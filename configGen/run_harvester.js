// jshint esversion:6

// First check the config

const fs = require('fs');
const Docker = require('node-docker-api').Docker;
const DockerEvents = require('docker-events');
const Dockerode = require('dockerode');
const which = require('which');
const { execFile } = require('child_process');
const _ = require('lodash');

const harvesterPathDfd = new Promise((resolve, reject) => {
    which('log.io-harvester', (err, path) => err ? reject(err) : resolve(path));
});

const requireExplicit = process.env.LOGIO_REQUIRE_EXPLICIT == 1;
const logio_nodeName = process.env.LOGIO_HARVESTER_NODENAME || "node";
const logio_streamPrefix = process.env.LOGIO_HARVESTER_PREFIX || null;
const logio_master = process.env.LOGIO_HARVESTER_MASTER_HOST || "logio";
const logio_masterPort = process.env.LOGIO_HARVESTER_MASTER_PORT || "28777";

const docker_sock = process.env.DOCKER_SOCKET || "/tmp/docker.sock";

const configFilePath = process.env.LOGIO_HARVESTER_CONFIG || "/root/.log.io/harvester.conf"

const dockerode = new Dockerode({socketPath: docker_sock})
const docker = new Docker({ socketPath: docker_sock });

const dockerEmitter = new DockerEvents({docker: dockerode});

function parseEnv(env) {
    let out = {};
    for (let e of env) {
        let [k, val] = e.split('=', 2);
        out[k] = val;
    }
    return out;
}

function refreshConfig() {

    // Detect all containers and get their status
    let containers = docker.container.list().then(list => Promise.all(list.map(c => c.status())));

    // Loop through and collect config information
    return containers.then(list => {
        const config = {};
        for (let c of list) {
            const cenv = parseEnv(c.data.Config.Env);
            // if requireExplicit is set then we only include containers with
            // LOGIO_INCLUDE=1 set in the environment
            if (requireExplicit && cenv.LOGIO_INCLUDE != 1 || cenv.LOGIO_EXCLUDE == 1) {
                continue;
            }
            // console.log(`env for ${c.data.Name}:`, cenv);
            let name = cenv.LOGIO_STREAM || c.data.Name.replace(/^\//g, '');
            if (logio_streamPrefix) { name = `${logio_streamPrefix}${name}`; }
            let logPath = c.data.LogPath;

            if (!config[name]) {
                config[name] = {
                    name: name,
                    path: []
                };
            }
            config[name].path.push(logPath);
        }
        return config;
    }).then(generateConfigFile);
}

function generateConfigFile(config) {
    let configFile = `
exports.config = {
    nodeName: ${JSON.stringify(logio_nodeName)},
    logStreams: {`;
    for (let stream of Object.keys(config)) {
        configFile += `
        ${JSON.stringify(stream)}: [`;
        for (let p of config[stream].path) {
            configFile += `
            ${JSON.stringify(p)},`;
        }
        configFile += `
        ],`;
    }

    configFile += `
    },
    server: {
        host: ${JSON.stringify(logio_master)},
        port: ${logio_masterPort}
    }
}
`;
    return configFile;
}

let updateConfig = function updateConfig(msg) {
    if (msg) {
        console.warn("Message from docker:", msg);
    }
    return refreshConfig().then(fileContents => {
        console.log("Writing new harvester config!", fileContents);
        fs.writeFileSync(configFilePath, fileContents);
        return startHarvester();
    }).catch(err => {
        console.warn("Error updating config file!", err);
    });
}
updateConfig = _.debounce(updateConfig, 500);

let harvester;
let harvestPath;
function startHarvester() {
    if (harvester) {
        harvester.kill();
        harvester = void 0;
        return;
    }
    harvester = execFile(harvestPath, (err, stdout, stderr) => {
        console.log("Harvester terminated:", err, stderr);
        setImmediate(startHarvester);
    });
    harvester.stdout.on('data', function (data) {
        console.log('stdout: ' + data.toString());
    });

    harvester.stderr.on('data', function (data) {
        console.log('stderr: ' + data.toString());
    });

    harvester.on('exit', function (code) {
        console.log('child process exited with code ' + code.toString());
    });    
    console.log("Re-spawned harvester");
}

function initHarvester() {
    harvesterPathDfd.then(hp => {
        console.log("Found harvester at", hp);
        harvestPath = hp;
        return updateConfig();
    }).catch(err => {
        console.warn("Could not initalize harvester!", err);
    });
}

dockerEmitter.on("connect", () => console.log("Connected to docker, waiting for events"));

dockerEmitter.on("start", updateConfig);
dockerEmitter.on("stop", updateConfig);
dockerEmitter.on("die", updateConfig);
// dockerEmitter.on("_message", message => console.log("got a message from docker: %j", message));

dockerEmitter.start();

initHarvester();