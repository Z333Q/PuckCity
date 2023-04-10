const CONTRACT_ADDRESS = "<your-contract-address>";
const PUCK_TOKEN_ADDRESS = "<your-puck-token-address>";
const baseURI = "https://puck.city/assets/";

// Team tokens
const CITY_TOKENS = [
  { name: "Anaheim", image: "anaheim.png" },
  { name: "Arizona", image: "arizona.png" },
  { name: "Boston", image: "boston.png" },
  { name: "Buffalo", image: "buffalo.png" },
  { name: "Calgary", image: "calgary.png" },
  { name: "Carolina", image: "carolina.png" },
  { name: "Chicago", image: "chicago.png" },
  { name: "Colorado", image: "colorado.png" },
  { name: "Columbus", image: "columbus.png" },
  { name: "Dallas", image: "dallas.png" },
  { name: "Detroit", image: "detroit.png" },
  { name: "Edmonton", image: "edmonton.png" },
  { name: "Florida", image: "florida.png" },
  { name: "Los Angeles", image: "los-angeles.png" },
  { name: "Minnesota", image: "minnesota.png" },
  { name: "Montreal", image: "montreal.png" },
  { name: "Nashville", image: "nashville.png" },
  { name: "New Jersey", image: "new-jersey.png" },
  { name: "New York Islanders", image: "new-york-islanders.png" },
  { name: "New York Rangers", image: "new-york-rangers.png" },
  { name: "Ottawa", image: "ottawa.png" },
  { name: "Philadelphia", image: "philadelphia.png" },
  { name: "Pittsburgh", image: "pittsburgh.png" },
  { name: "San Jose", image: "san-jose.png" },
    { name: "Seattle", image: "seattle.png" },
  { name: "St. Louis", image: "st-louis.png" },
  { name: "Tampa Bay", image: "tampa-bay.png" },
  { name: "Toronto", image: "toronto.png" },
  { name: "Vancouver", image: "vancouver.png" },
  { name: "Vegas", image: "vegas.png" },
  { name: "Washington", image: "washington.png" },
  { name: "Winnipeg", image: "winnipeg.png" },
];

// Load web3
const loadWeb3 = async () => {
  if (window.ethereum) {
    window.web3 = new Web3(window.ethereum);
    await window.ethereum.request({ method: "eth_requestAccounts" });
  } else if (window.web3) {
    window.web3 = new Web3(window.web3.currentProvider);
  } else {
    window.alert("Non-Ethereum browser detected. You should consider trying MetaMask!");
  }
};

// Load contract
async function loadContract() {
  const response = await fetch("assets/PuckCityV7.json");
  const data = await response.json();
  const networkType = await web3.eth.net.getNetworkType();
  const networkId = await web3.eth.net.getId();
  const contractAddress = networkType === 'test' ? CONTRACT_ADDRESS : "<your-contract-address-mainnet>";
// Define contract and token addresses
const CONTRACT_ADDRESS = "<your-contract-address>";
const PUCK_TOKEN_ADDRESS = "<your-puck-token-address>";
const baseURI = "https://puck.city/assets/";

// Define team tokens
const TEAM_TOKENS = [
{ name: "Anaheim", address: "0x...", image: "anaheim.png" },
{ name: "Arizona", address: "0x...", image: "arizona.png" },
{ name: "Boston", address: "0x...", image: "boston.png" },
{ name: "Buffalo", address: "0x...", image: "buffalo.png" },
{ name: "Calgary", address: "0x...", image: "calgary.png" },
{ name: "Carolina", address: "0x...", image: "carolina.png" },
{ name: "Chicago", address: "0x...", image: "chicago.png" },
{ name: "Colorado", address: "0x...", image: "colorado.png" },
{ name: "Columbus", address: "0x...", image: "columbus.png" },
{ name: "Dallas", address: "0x...", image: "dallas.png" },
{ name: "Detroit", address: "0x...", image: "detroit.png" },
{ name: "Edmonton", address: "0x...", image: "edmonton.png" },
{ name: "Florida", address: "0x...", image: "florida.png" },
{ name: "Los Angeles", address: "0x...", image: "los-angeles.png" },
{ name: "Minnesota", address: "0x...", image: "minnesota.png" },
{ name: "Montreal", address: "0x...", image: "montreal.png" },
{ name: "Nashville", address: "0x...", image: "nashville.png" },
{ name: "New Jersey", address: "0x...", image: "new-jersey.png" },
{ name: "New York Islanders", address: "0x...", image: "new-york-islanders.png" },
{ name: "New York Rangers", address: "0x...", image: "new-york-rangers.png" },
{ name: "Ottawa", address: "0x...", image: "ottawa.png" },
{ name: "Philadelphia", address: "0x...", image: "philadelphia.png" },
{ name: "Pittsburgh", address: "0x...", image: "pittsburgh.png" },
{ name: "San Jose", address: "0x...", image: "san-jose.png" },
  { name: "Seattle", address: "0x...", image: "seattle.png" },
{ name: "St. Louis", address: "0x...", image: "st-louis.png" },
{ name: "Tampa Bay", address: "0x...", image: "tampa-bay.png" },
{ name: "Toronto", address: "0x...", image: "toronto.png" },
{ name: "Vancouver", address: "0x...", image: "vancouver.png" },
{ name: "Vegas", address: "0x...", image: "vegas.png" },
{ name: "Washington", address: "0x...", image: "washington.png" },
{ name: "Winnipeg", address: "0x...", image: "winnipeg.png" },
];

// Load Web3
async function loadWeb3() {
if (window.ethereum) {
window.web3 = new Web3(window.ethereum);
await window.ethereum.request({ method: "eth_requestAccounts" });
} else if (window.web3) {
window.web3 = new Web3(window.web3.currentProvider);
} else {
window.alert("Non-Ethereum browser detected. You should consider trying MetaMask!");
}
}

// Load Contract
async function loadContract() {
const response = await fetch("assets/PuckCityV8.json");
const data = await response.json();
const networkType = await web3.eth.net.getNetworkType();
const networkId = await web3.eth.net.getId();
const contractAddress = networkType === 'test' ? CONTRACT_ADDRESS : "<your-contract-address-mainnet>";
const contract = new web3.eth.Contract(data.abi, contractAddress);
return contract;
}

// Load Account
async function loadAccount() {
const accounts = await web3.eth.getAccounts();
return accounts[0];
}

// Refresh data
async function refreshData() {
const contract = await loadContract();
const account = await loadAccount();

// Get city token balances
const cityTokenBalance = await contract.methods.balanceOf(CITY_TOKEN_ADDRESS, account).call();
const cityToken = await fetch(baseURI + CITY_TOKEN_ADDRESS);
const cityTokenData = await cityToken.json();
const cityTokenSymbol = cityTokenData.symbol;
const cityTokenDecimals = cityTokenData.decimals;
const cityTokenBalanceFormatted = web3.utils.fromWei(cityTokenBalance, "ether");

// Get puck token balances
const puckTokenBalance = await contract.methods.balanceOf(PUCK_TOKEN_ADDRESS, account).call();
const puckToken = await fetch(baseURI + PUCK_TOKEN_ADDRESS);
const puckTokenData = await puckToken.json();
const puckTokenSymbol = puckTokenData.symbol;
const puckTokenDecimals = puckTokenData.decimals;
const puckTokenBalanceFormatted = web3.utils.fromWei(puckTokenBalance, "ether");

// Get staked balances
const stakedBalances = [];
const stakedCityTokenBalance = await contract.methods.stakedBalance(CITY_TOKEN_ADDRESS, account).call();
if (stakedCityTokenBalance > 0) {
stakedBalances.push({
name: cityTokenData.name,
symbol: cityTokenData.symbol,
image: "https://puck.city/assets/city-token.png",
balance: web3.utils.fromWei(stakedCityTokenBalance, "ether"),
address: CITY_TOKEN_ADDRESS
});
}
const stakedPuckTokenBalance = await contract.methods.stakedBalance(PUCK_TOKEN_ADDRESS, account).call();
if (stakedPuckTokenBalance > 0) {
stakedBalances.push({
name: puckTokenData.name,
symbol: puckTokenData.symbol,
image: "https://puck.city/assets/puck-token.png",
balance: web3.utils.fromWei(stakedPuckTokenBalance, "ether"),
address: PUCK_TOKEN_ADDRESS
});
}

// Get total staked balance
const stakedBalancesSum = stakedBalances.reduce((total, balance) => total.add(web3.utils.toBN(web3.utils.toWei(balance.balance))), web3.utils.toBN(0));
const totalStakedBalance = web3.utils.fromWei(stakedBalancesSum, "ether");

// Get total rewards earned
const totalRewards = await contract.methods.getRewards(account).call();

// Get available rewards balance
const availableRewardsBalance = await contract.methods.getAvailableRewards(account).call();

// Display city token balance
const cityTokenBalanceElement = document.getElementById("cityTokenBalance");
cityTokenBalanceElement.textContent = ${cityTokenBalanceFormatted} ${cityTokenSymbol};

// Display puck token balance
const puckTokenBalanceElement = document.getElementById("puckTokenBalance");
puckTokenBalanceElement.textContent = ${puckTokenBalanceFormatted} ${puckTokenSymbol};

// Display staked token balances
const stakedTokenList = document.getElementById("stakedTokenList");
stakedTokenList.innerHTML = "";
stakedBalances.forEach((stakedBalance) => {
const stakedTokenItem = document.createElement("li");
stakedTokenItem.classList.add("list-group-item");
const stakedTokenImage = document.createElement("img");
stakedTokenImage.src = stakedBalance.image;
stakedTokenImage.classList.add("staked-token-image");
const stakedTokenName = document.createElement("span");
stakedTokenName.textContent = stakedBalance.name;
stakedTokenName.classList.add("staked-token-name");
const stakedTokenBalance = document.createElement("span");
stakedTokenBalance.textContent = ${stakedBalance.balance.toFixed(2)} ${stakedBalance.symbol};
stakedTokenBalance.classList.add("staked-token-balance");
stakedTokenItem.appendChild(stakedTokenImage);
stakedTokenItem.appendChild(stakedTokenName);
stakedTokenItem.appendChild(stakedTokenBalance);
stakedTokenList.appendChild(stakedTokenItem);
});

// Display total staked token balance
const totalStakedTokenBalanceElement = document.getElementById("totalStakedTokenBalance");
totalStakedTokenBalanceElement.textContent = ${totalStakedBalance.toFixed(2)} ${cityTokenSymbol};

// Display total rewards earned
const totalRewardsEarnedElement = document.getElementById("totalRewardsEarned");
totalRewardsEarnedElement.textContent = ${totalRewards.toFixed(2)} PUCK;

// Display available rewards balance
const availableRewardsElement = document.getElementById("availableRewards");
availableRewardsElement.textContent = ${availableRewardsBalance.toFixed(2)} PUCK;

// Display team token balances
const teamTokenList = document.getElementById("teamTokenList");
teamTokenList.innerHTML = "";
teamTokens.forEach(async (teamToken) => {
const teamTokenBalance = await contract.methods.balanceOf(teamToken.address, account).call();
const teamTokenBalanceFormatted = web3.utils.fromWei(teamTokenBalance, "ether");
const teamTokenItem = document.createElement("li");
teamTokenItem.classList.add("list-group-item");
const teamTokenImage = document.createElement("img");
teamTokenImage.src = baseURI + teamToken.image;
teamTokenImage.classList.add("team-token-image");
const teamTokenName = document.createElement("span");
teamTokenName.textContent = teamToken.name;
teamTokenName.classList.add("team-token-name");
const teamTokenBalanceElement = document.createElement("span");
teamTokenBalanceElement.textContent = ${teamTokenBalanceFormatted} ${teamToken.symbol};
teamTokenBalanceElement.classList.add("team-token-balance");
teamTokenItem.appendChild(teamTokenImage);
teamTokenItem.appendChild(teamTokenName);
teamTokenItem.appendChild(teamTokenBalanceElement);
teamTokenList.appendChild(teamTokenItem);
});

// Handle staking form submission
const stakingForm = document.getElementById("stakingForm");
stakingForm.addEventListener("submit", async (event) => {
event.preventDefault();
const amount = event.target.elements[0].value;
const team = event.target.elements[1].value;
await stake(team, amount);
event.target.reset();
});

// Handle unstake button click
const unstakeButtons = document.querySelectorAll(".unstake-button");
unstakeButtons.forEach((unstakeButton) => {
unstakeButton.addEventListener("click", async (event) => {
const team = event.target.getAttribute("data-team");
const amount = window.prompt(Enter the amount of ${team} you want to unstake);
if (amount !== null) {
await unstake(team, amount);
}
});
});

// Handle claim button click
const claimButton = document.getElementById("claimButton");
claimButton.addEventListener("click", async (event) => {
await claim();
});

// Stake tokens
async function stake(team, amount) {
const contract = await loadContract();
const account = await loadAccount();
const teamToken = teamTokens.find((t) => t.name === team);
const teamTokenId = teamToken.address;
const amountInWei = web3.utils.toWei(amount, "ether");

// Approve tokens for staking
const approved = await contract.methods.allowance(account, CONTRACT_ADDRESS, teamTokenId).call();
if (web3.utils.toBN(approved).lt(web3.utils.toBN(amountInWei))) {
await contract.methods.approve(CONTRACT_ADDRESS, teamTokenId, amountInWei).send({ from: account });
}

// Stake tokens
await contract.methods.stake(teamTokenId, amountInWei).send({ from: account });

// Refresh data
await refreshData();
}

// Unstake tokens
async function unstake(team, amount) {
const contract = await loadContract();
const account = await loadAccount();
const teamToken = teamTokens.find((t) => t.name === team);
const teamTokenId = teamToken.address;
const amountInWei = web3.utils.toWei(amount, "ether");

// Unstake tokens
await contract.methods.unstake(teamTokenId, amountInWei).send({ from: account });

// Refresh data
await refreshData();
}

// Claim rewards
async function claim() {
const contract = await loadContract();
const account = await loadAccount();

// Claim rewards
await contract.methods.claim().send({ from: account });

// Refresh data
await refreshData();
}

// Load data on page load
window.addEventListener("load", async () => {
await loadWeb3();
await refreshData();
});
