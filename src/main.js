import Web3 from 'web3'
import { newKitFromWeb3 } from '@celo/contractkit'
import BigNumber from "bignumber.js"
import marketplaceAbi from '../contract/marketplace.abi.json'
import erc20Abi from "../contract/erc20.abi.json"


const ERC20_DECIMALS = 18
const MPContractAddress = "0x09d6bC4FBdd071FE298D629C5a7cDb6fA483F43f"
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1"

let kit
let contract
let items = []

const connectCeloWallet = async function () {
  if (window.celo) {
    notification("Dapp is requesting permission to connect to your wallet: ")
    try {
      await window.celo.enable()
      notificationOff()

      const web3 = new Web3(window.celo)
      kit = newKitFromWeb3(web3)

      const accounts = await kit.web3.eth.getAccounts()
      kit.defaultAccount = accounts[0]

      contract = new kit.web3.eth.Contract(marketplaceAbi, MPContractAddress)
    } catch (error) {
      notification(`⚠️ ${error}.`)
    }
  } else {
    notification("Install the CeloExtensionWallet to use this Dapp.")
  }
}

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress)

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount })
  return result
}


const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount)
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2)
  document.querySelector("#balance").textContent = cUSDBalance
}

const getItems = async function() {
  const _numberOfItemsAvailable = await contract.methods.totalAccessoriesAvailable().call()
  const _items = []

  for (let i = 0; i < _numberOfItemsAvailable; i++) {
    let _item = new Promise(async (resolve, reject) => {
      let p = await contract.methods.viewItem(i).call()
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        description: p[3],
        price: new BigNumber(p[4]),
        tempPrice: new BigNumber(p[5]),
        sold:p[6],
        units:p[7],
        nLikes:p[8]
      })
    })
    _items.push(_item)
  }
  items = await Promise.all(_items)
  renderAccessories()
}


function renderAccessories() {
  document.getElementById("marketplace").innerHTML = ""
  items.forEach((_item) => {
    const newDiv = document.createElement("div")
    newDiv.className = "col-md-4"
    newDiv.innerHTML = AccessoryTemplate(_item)
    document.getElementById("marketplace").appendChild(newDiv)
  })
}



function AccessoryTemplate(_item) {
  return `
    <div class="card mb-4">
      <img class="card-img-top" src="${_item.image}" alt="...">
      <div class="position-absolute top-0 end-0 bg-light mt-4 px-2 py-1 rounded-start">sold: ${_item.sold}pieces</div>
      <div class="card-body text-left p-4 position-relative">
        <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_item.owner)}
        </div>
        <h2 class="card-title fs-4 fw-bold mt-2">${_item.name}</h2>
        <p class="card-text mb-4" style="min-height: 82px">
          ${_item.description}             
        </p>
        ${
            _item.units != 0? `<p class="card-text mt-4">
            <i class="bi bi-card-list"></i>
            <span>Available : ${_item.units} pieces</span>
          </p>
          <div class="d-grid gap-2">
              <a class="btn btn-lg btn-outline-info buyBtn fs-6 p-3" id=${
                _item.index
              }>
                Buy for ${_item.price.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
              </a>
            </div>`
            :
            `<p class="card-text mt-4">
            <i class="bi bi-card-list"></i>
            <span>No longer in stock</span>
          </p>`
        }
      </div>
    </div>
  `
}


function identiconTemplate(_address) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL()

  return `
  <div class="rounded-circle overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `
}

function notification(_text) {
  document.querySelector(".alert").style.display = "block"
  document.querySelector("#notification").textContent = _text
}

function notificationSuccess(_text) {
    document.querySelector(".alert").style.color = "green"
    document.querySelector(".alert").style.display = "block"
    document.querySelector("#notification").textContent = _text
  }

function notificationError(_text) {
    document.querySelector(".alert").style.color = "red"
    document.querySelector(".alert").style.display = "block"
    document.querySelector("#notification").textContent = _text
  }

function notificationOff() {
  document.querySelector(".alert").style.display = "none"
}


window.addEventListener('load', async () => {
  notification("⌛ Loading...")
  await connectCeloWallet()
  await getBalance()
  await getItems()
  notificationOff()
});


document
  .querySelector("#newItemBtn")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newItemName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newItemDescription").value,
      new BigNumber(document.getElementById("newPrice").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString(),
      document.getElementById("newUnitsAvailable").value
    ]
    notification(`⌛ currently adding "${params[0]}"...`)
    try {
      const result = await contract.methods
        .addItem(...params)
        .send({ from: kit.defaultAccount })
    } catch (error) {
      notificationError(`⚠️ ${error}.`)
    }
    notificationSuccess(`congratulations: "${params[0]}" added successfully 🎉`)
    getItems()
  })


 document.querySelector("#marketplace").addEventListener("click", async (e) => {
  if (e.target.className.includes("buyBtn")) {
    const index = e.target.id
    const units = prompt("How many pieces do you want?")
    if (units!=null){
      notification("⌛ Waiting for payment approval...")
    try {
      await approve(items[index].price)
    } catch (error) {
      notificationErroe(`⚠️ ${error}.`)
    }
    notification(`⌛ Awaiting payment for ${units} piece(s) of "${items[index].name}"...`)
    try {
      const result = await contract.methods
        .buyItem(index,units)
        .send({ from: kit.defaultAccount })
      notificationSuccess(`congratulations : You successfully bought ${units} piece(s) of "${items[index].name}". `)
      getItems()
      getBalance()
    } catch (error) {
      notificationError(`⚠️ ${error}.`)
    }

    }
      }
  })
