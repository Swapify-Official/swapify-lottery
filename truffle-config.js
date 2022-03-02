require('dotenv').config()

const HDWalletProvider = require('@truffle/hdwallet-provider');


module.exports = {
  contracts_build_directory: "./trufflebuild",
  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache-cli, geth or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //
     development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 9545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
     },
     matic: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, `https://rpc-mumbai.maticvigil.com/v1/3d8e023feb718b64c09bd40bf0ce1b49a5061daa`),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
      production: true
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.0",    // Fetch exact version from solc-bin (default: truffle's version)
      optimizer: {
        enabled: true,
        runs: 1500
      }
    }
  },

  // Plugins
  plugins: ['truffle-plugin-verify'],

  // API keys
  api_keys: {
    etherscan: '9VIZCAMV8XK5W3YZJZM5FMG82SWFWPAW6H',
    polygonscan: '859A4658ZBPDHUK3N1462SJ7U43KP2MJGE'
  }
};
