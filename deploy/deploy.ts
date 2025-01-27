import { ethers } from 'hardhat';
const prompt = require('prompt-sync')();

const chainLinkAddresses = {
	bscTestnet: ['0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526', 3600],
	bsc: ['0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE', 3600],
	polygonAmoy: ['0x001382149eBa3441043c1c66972b4772963f5D43', 120],
	polygon: ['0xAB594600376Ec9fD91F8e885dADF0CE036862dE0', 27],
	base: ['0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70', 1200],
	linea: ['0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA', 86400],
	ethereumMainnet: ['0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', 3600],
	sepolia: ['0x694AA1769357215DE4FAC081bf1f309aDC325306', 3600],
	redbellyTestNet: ['0x694AA1769357215DE4FAC081bf1f309aDC325306', 3600], // INFO: This is not correct
	skale: ['0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', 120], // INFO: This is not correct
	skaleCalypso: ['0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419', 120], // INFO: This is not correct
	baseSepolia: ['0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1', 12000], // INFO: This is not correct
	redbelly: ['0x0CD42d829F88fe539f710E9b7692C70b94aaEad4', 120], // INFO: This is not correct
	bitlayerTestnet: ['0x0CD42d829F88fe539f710E9b7692C70b94aaEad4', 120], // INFO: This is not correct
};

async function main() {
	console.log('[ 👾 ] Initializing...');
	console.log(
		`[ 👾 ] Deploying to chain: ${(await ethers.provider.getNetwork()).name}`
	);
	const network = (await ethers.provider.getNetwork()).name;

	let heartBeat;
	let chainLinkAddress;
	if ((chainLinkAddresses as any)[network] != undefined) {
		chainLinkAddress = (chainLinkAddresses as any)[network][0];
		heartBeat = (chainLinkAddresses as any)[network][1];
	} else {
		chainLinkAddress = prompt('[ 🧐 ] Chain Link address: ');
		heartBeat = parseInt(prompt('[ 🧐 ] Heartbeat: '));
	}
	console.log(`[ 👾 ] Chain Link address set to: ${chainLinkAddress}`);

	const ProxyPayer = await ethers.getContractFactory('DroplinkedPaymentProxy');
	const proxyPayer = await ProxyPayer.deploy(heartBeat, chainLinkAddress);
	console.log('[ ✅ ] ProxyPayer deployed to: ', await proxyPayer.getAddress());
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
