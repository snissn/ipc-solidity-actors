import { HardhatUserConfig, task } from "hardhat/config";
import '@typechain/hardhat';
import "hardhat-storage-layout-changes";

import "@nomicfoundation/hardhat-foundry";
import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy";
import "hardhat-contract-sizer";

import dotenv from "dotenv";
import fs from "fs";
import { HardhatRuntimeEnvironment } from "hardhat/types";

dotenv.config();

const lazyImport = async (module: any) => {
  return await import(module);
};

async function saveDeployments(env: string, deploymentData: { [key in string]: string }, branch?: string) {
  const deploymentsJsonPath = `${process.cwd()}/deployments.json`;

  let deploymentsJson = { [env]: {} };
  if (fs.existsSync(deploymentsJsonPath)) {
    deploymentsJson = JSON.parse(fs.readFileSync(deploymentsJsonPath).toString());
  }

  if (branch) {
    deploymentsJson[env] = { ...deploymentsJson[env], [branch]: deploymentData }
  } else {
    deploymentsJson[env] = { ...deploymentsJson[env], ...deploymentData }
  }

  fs.writeFileSync(deploymentsJsonPath, JSON.stringify(deploymentsJson));
}

async function getDeployments(env: string): Promise<{ [key in string]: string }> {
  const deploymentsJsonPath = `${process.cwd()}/deployments.json`;

  let deployments = {};
  if (fs.existsSync(deploymentsJsonPath)) {
    deployments = JSON.parse(fs.readFileSync(deploymentsJsonPath).toString())[env];
  }

  return deployments;
}

task('deploy-libraries', 'Build and deploys all libraries on the selected network', async (args, hre: HardhatRuntimeEnvironment) => {
  const { deploy } = await lazyImport('./scripts/deploy-libraries');
  const libsDeployment = await deploy();
  console.log(libsDeployment);
  await saveDeployments(hre.network.name, libsDeployment, 'libs');
});

task('deploy-gateway', 'Builds and deploys the Gateway contract on the selected network', async (args, hre: HardhatRuntimeEnvironment) => {
  const network = hre.network.name;

  const deployments = await getDeployments(network);
  const { deploy } = await lazyImport('./scripts/deploy-gateway');
  const gatewayDeployment = await deploy(deployments.libs);

  console.log(gatewayDeployment);

  await saveDeployments(network, gatewayDeployment);
});

task('deploy-subnet', 'Builds and deploys the SubnetActor contract on the selected network', async (args, hre: HardhatRuntimeEnvironment) => {
  const network = hre.network.name;

  const deployments = await getDeployments(network);
  const { deploy } = await lazyImport('./scripts/deploy-subnet');

  // remove unused lib
  delete deployments.libs["StorableMsgHelper"];

  const subnetDeployment = await deploy(deployments.Gateway, deployments.libs);

  console.log(subnetDeployment);

  await saveDeployments(network, subnetDeployment);
});

task('deploy-gw-diamond-and-facets', 'Builds and deploys Gateway Actor diamond and its facets', async (args, hre: HardhatRuntimeEnvironment) => {
  const network = hre.network.name;
  const deployments = await getDeployments(network);
  const { deployDiamond } = await lazyImport('./scripts/deploy-gw-diamond');
  const gatewayActorDiamond = await deployDiamond(deployments.libs);
  console.log(gatewayActorDiamond);
  await saveDeployments(network, gatewayActorDiamond);
});

task('deploy-sa-diamond-and-facets', 'Builds and deploys Subnet Actor diamond and its facets', async (args, hre: HardhatRuntimeEnvironment) => {
  const network = hre.network.name;
  const deployments = await getDeployments(network);
  const { deployDiamond } = await lazyImport('./scripts/deploy-sa-diamond');
  const subnetActorDiamond = await deployDiamond(deployments.GatewayActorDiamond,deployments.libs);
  console.log(subnetActorDiamond);
  await saveDeployments(network, subnetActorDiamond);
});

task('deploy', 'Builds and deploys all contracts on the selected network', async (args, hre: HardhatRuntimeEnvironment) => {
  await hre.run('compile');
  await hre.run('deploy-libraries');
  await hre.run('deploy-gateway');
});

task('deploy-gw-diamond', 'Builds and deploys Gateway Actor diamond', async (args, hre: HardhatRuntimeEnvironment) => {
  await hre.run('compile');
  await hre.run('deploy-libraries');
  await hre.run('deploy-gw-diamond-and-facets');
});

task('deploy-sa-diamond', 'Builds and deploys Subnet Actor diamond', async (args, hre: HardhatRuntimeEnvironment) => {
  await hre.run('compile');
  await hre.run('deploy-libraries');
  await hre.run('deploy-sa-diamond-and-facets');
});

/** @type import('hardhat/config').HardhatUserConfig */
const config: HardhatUserConfig = {
  defaultNetwork: "calibrationnet",
  networks: {
    mainnet: {
      chainId: 314,
      url: process.env.RPC_URL!,
      accounts: [process.env.PRIVATE_KEY!],
      timeout: 1000000,
    },
    calibrationnet: {
      chainId: 314159,
      url: process.env.RPC_URL!,
      accounts: [process.env.PRIVATE_KEY!],
      timeout: 1000000,
    },
    localnet: {
      chainId: 31415926,
      url: process.env.RPC_URL!,
      accounts: [process.env.PRIVATE_KEY!],
    }
  },
  solidity: {
    compilers: [
      {
        version: '0.8.19',
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5',
  },
  paths: {
    storageLayouts: ".storage-layouts",
  },
  storageLayoutChanges: {
    contracts: [
      'GatewayDiamond',
      'SubnetActorDiamond',
      'GatewayActorModifiers',
      'SubnetActorModifiers',
    ],
    fullPath: false,
  },
};

export default config;

