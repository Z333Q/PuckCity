const CONTRACT_ADDRESS = "<your-contract-address>";
const PUCK_TOKEN_ADDRESS = "<your-puck-token-address>";
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
    await window.ethereum.enable();
  } else if (window.web3) {
    window.web3 = new Web3(window.web3.currentProvider);
  } else {
    window.alert("Non-Ethereum browser detected. You should consider trying MetaMask!");
  }
};

// Load contract
async function loadContract() {
  const response = await fetch(assets/PuckCityV6.json);
  const data = await response.json();
  const networkId = await web3.eth.net.getId();
  const baseURI = "https://example.com/token/";
  const tokenAddress = "<your-token-address>";
  const treasuryAddress = "<your-treasury-address>";
  const aggregatorAddress = "<your-aggregator-address>";
  const contract = new web3.eth.Contract(data.abi, CONTRACT_ADDRESS);
  return contract;
}

// Load account
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
      image: "https://example.com/city-token.png",
      balance: web3.utils.fromWei(stakedCityTokenBalance, "ether"),
      address: CITY_TOKEN_ADDRESS
    });
  }
  const stakedPuckTokenBalance = await contract.methods.stakedBalance(PUCK_TOKEN_ADDRESS, account).call();
  if (stakedPuckTokenBalance > 0) {
    stakedBalances.push({
      name: puckTokenData.name,
      symbol: puckTokenData.symbol,
      image: "https://example.com/puck-token.png",
      balance: web3.utils.fromWei(stakedPuckTokenBalance, "ether"),
      address: PUCK_TOKEN_ADDRESS
    });
  }
  
  // Get total staked balance
  const totalStakedBalance = web3.utils.fromWei(Number(stakedCityTokenBalance) + Number(stakedPuckTokenBalance), "ether"),
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

// Display staked city token balances
const stakedCityTokenList = document.getElementById("stakedCityTokenList");
stakedCityTokenList.innerHTML = "";
stakedBalances.forEach((stakedBalance) => {
const stakedCityTokenItem = document.createElement("li");
stakedCityTokenItem.classList.add("list-group-item");
const stakedCityTokenImage = document.createElement("img");
stakedCityTokenImage.src = stakedBalance.image;
stakedCityTokenImage.classList.add("city-token-image");
const stakedCityTokenName = document.createElement("span");
stakedCityTokenName.textContent = stakedBalance.name;
stakedCityTokenName.classList.add("city-token-name");
const stakedCityTokenBalance = document.createElement("span");
stakedCityTokenBalance.textContent = ${stakedBalance.balance.toFixed(2)} ${stakedBalance.symbol};
const stakedCityTokenBalanceIcon = document.createElement("i");
stakedCityTokenBalanceIcon.classList.add("fas", "fa-hockey-puck");
stakedCityTokenBalance.appendChild(stakedCityTokenBalanceIcon);
stakedCityTokenItem.appendChild(stakedCityTokenImage);
stakedCityTokenItem.appendChild(stakedCityTokenName);
stakedCityTokenItem.appendChild(stakedCityTokenBalance);
stakedCityTokenList.appendChild(stakedCityTokenItem);
});

// Display total staked city token balance
const totalStakedCityTokenBalance = document.getElementById("totalStakedCityTokenBalance");
totalStakedCityTokenBalance.textContent = ${totalStakedBalance.toFixed(2)} CITY;

// Display total rewards earned
const totalRewardsEarned = document.getElementById("totalRewardsEarned");
totalRewardsEarned.textContent = ${totalRewards.toFixed(2)} PUCK;

// Display available rewards
const availableRewards = document.getElementById("availableRewards");
availableRewards.textContent = ${availableRewardsBalance.toFixed(2)} PUCK;
}

// Load contract
async function loadContract() {
const response = await fetch(assets/PuckCityV6.json);
const data = await response.json();
const networkId = await web3.eth.net.getId();
const baseURI = "https://example.com/token/";
const tokenAddress = "<your-token-address>";
const treasuryAddress = "<your-treasury-address>";
const aggregatorAddress = "<your-aggregator-address>";
const contract = new web3.eth.Contract(data.abi, CONTRACT_ADDRESS);
return contract;
}

// Load account
async function loadAccount() {
const accounts = await web3.eth.getAccounts();
return accounts[0];
}

// Refresh data on page load
window.addEventListener("load", async () => {
await refreshData();
});

// Display staking form
const stakingForm = document.getElementById("stakingForm");
stakingForm.addEventListener("submit", async (event) => {
event.preventDefault();
const amount = event.target.elements[0].value;
const token = event.target.elements


