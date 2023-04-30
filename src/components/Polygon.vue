<!--./src/components/Polygon.vue -->

<template>
  <div class="section text-center m-4">
    <p class="text-red-500 mb-2" v-if="hasError()">{{ errorMessage }}</p>
    <p class="text-blue-500 mb-2" v-if="hasNotice()">
      {{ noticeMessage }}
    </p>
    <div v-if="hasActiveAccount()">
      <div v-if="isAssetsView()">
        <p class="text-lg mt-4 mb-2 font-semibold">
          <img class="mx-auto mb-2 w-16" src="/img/matic.png"  alt=""/>
          {{ MATICBalance(balance) }} MATIC
        </p>
        <button
          @click="showWithdrawal()"
          class="
            m-1
            bg-blue-500
            hover:bg-blue-600
            active:bg-blue-700
            text-white
            font-bold
            py-2
            px-4
            rounded
          "
        >
          Send
        </button>

      </div>
      <div v-if="isWithdrawaltView()">
        <div class="max-w-xs m-auto">
          <div class="field-group">
            <img class="w-16 block mb-2 mx-auto" src="/img/matic.png"  alt=""/>
            <select
              v-model="sendContract"
              class="
                field
                p-2
                font-mono
                w-full
                outline-none
                rounded-l
                mb-4
                bg-white
              "
            >
              <option value="">MATIC - {{ balance }}</option>
            </select>
            <label class="field-label block mb-1" for="recipient"
              >- Recipient -</label
            >
            <div class="flex items-center">
              <div class="w-full">
                <input
                  v-model="sendTo"
                  class="field p-2 font-mono w-full outline-none rounded-l"
                  type="text"
                  name="recipient"
                  id="recipient"
                />
              </div>
            </div>
          </div>
          <div class="field-group my-6">
            <label class="field-label block mb-1" for="recipient"
              >- Amount -</label
            >
            <div class="flex items-center w-full min-w-full">
              <div class="w-full">
                <input
                  v-model="sendAmount"
                  class="field p-2 font-mono w-full outline-none rounded-l"
                  placeholder="0"
                  type="number"
                  name="amount"
                  id="amount"
                />
              </div>
              <div>
                <button
                  @click="maxSend()"
                  class="
                    bg-blue-500
                    hover:bg-blue-600
                    active:bg-blue-700
                    text-white
                    font-bold
                    py-2
                    px-3
                    rounded-r
                    align-bottom
                  "
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 4v16m8-8H4"
                    />
                  </svg>
                </button>
              </div>
            </div>
          </div>
          <button
            @click="goHome()"
            class="
              m-1
              bg-gray-500
              hover:bg-blue-600
              active:bg-blue-700
              text-white
              font-bold
              py-2
              px-4
              rounded
              align-bottom
            "
          >
            Cancel
          </button>
          <button
            @click="sendAction()"
            class="
              m-1
              bg-blue-500
              hover:bg-blue-600
              active:bg-blue-700
              text-white
              font-bold
              py-2
              px-4
              rounded
              align-bottom
            "
          >
            Send
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Web3 from "web3/dist/web3.min.js";
import Decimal from "decimal.js";
import { setIntervalAsync } from "set-interval-async/fixed";
import { BigNumber } from "bignumber.js";

const web3js = new Web3("https://polygon-rpc.com/");
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Debugging helpers.
window.web3js = web3js;
window.Web3NoMeta = Web3;

export default {
  name: "SmartMask",
  data: function () {
    return {
      accounts: [],
      activeAccount: "",
      attemptedRegistration: false,
      balance: new BigNumber(0),
      bindingRetries: 0,
      bindingsAdded: false,
      connected: null,
      currentView: "assets",
      errorMessage: "",
      noCopy: null,
      noticeMessage: "",
      pendingConnection: null,
      sendAmount: new BigNumber(0),
      sendContract: "",
      sendTo: "",
      stopRequests: false,
      timer: null,
    };
  },
  components: {
  },
  mounted: async function () {
    await this.checkState();
    this.timer = setIntervalAsync(this.checkState, 5000);
  },
  methods: {
    onScan: function (result) {
      try {
        this.sendTo = web3js.utils.toChecksumAddress(
          this.parseScanResult(result)
        );
        this.showWithdrawal();
      } catch (e) {
        this.setError("Invalid Recipient Address: " + e.message);
      }
    },
    parseScanResult: function (result) {
      return result.replace("ethereum:", "");
    },
    addBindings: function () {
      if (!this.backendAvailable() || this.bindingsAdded) {
        this.bindingRetries += 1;
        return;
      }

      if (window.ethereum.isMetaMask) {
        window.ethereum.on("accountsChanged", (chainId) => {
          this.resetConnection();
          this.updateAccount();
        });

        window.ethereum.on("chainChanged", (chainId) => {
          this.resetConnection();
          this.checkState();
        });
      }

      this.bindingsAdded = true;
    },
    sendingMATIC: function () {
      return this.sendContract === "";
    },
    isWithdrawaltView: function () {
      return this.currentView === "withdrawal";
    },
    isAssetsView: function () {
      return this.currentView === "assets";
    },
    showWithdrawal: function () {
      this.resetNotices();

      this.currentView = "withdrawal";
    },
    showAssets: function () {
      this.resetNotices();

      this.currentView = "assets";
    },
    resetNotices: function () {
      this.errorMessage = "";
      this.noticeMessage = "";
    },
    goHome: function () {
      this.showAssets();
    },
    sendAction: function () {
      if (this.validateSend()) {
        this.resetNotices();
        if (this.sendingMATIC()) {
          this.sendMATIC();
        }
      }
    },
    sendMATIC: function () {
      let value = web3js.utils.toWei(this.sendAmount.toString(), "ether");
      const gasPrice = web3js.utils.toWei("0.00000000105", "ether");
      const gas = "21000";

      // Send max case, deduct the gas from the value.
      if (this.sendAmount.toString() === this.balance.toString()) {
        value =
          new BigNumber(value) - new BigNumber(gas) * new BigNumber(gasPrice);

        if (value < 0) {
          value = "0";
        } else {
          value = value.toString();
        }
      }

      window.ethereum
        .request({
          method: "eth_sendTransaction",
          params: [
            {
              from: this.activeAccount,
              to: web3js.utils.toChecksumAddress(this.sendTo),
              value: web3js.utils.toHex(value),
              gas: web3js.utils.toHex(gas),
              gasPrice: web3js.utils.toHex(gasPrice),
            },
          ],
        })
        .then((txHash) => console.log(txHash))
        .catch((error) => console.log(error));
    },
    validateSend: function () {
      try {
        const address = web3js.utils.toChecksumAddress(this.sendTo);
      } catch (e) {
        this.setError("Invalid Recipient Address");
        return false;
      }

      if (this.sendingMATIC() && this.sendAmount > this.balance) {
        this.setError("Invalid amount");
        return false;
      }

      return true;
    },
    maxSend: function () {
      if (this.sendingMATIC()) {
        this.sendAmount = this.balance;
      }
    },
    setError: function (text) {
      this.errorMessage = text;
      this.errorDate = Date.now();
    },
    MATICBalance: function (bal) {
      return new BigNumber(bal.toFixed(8)).toString();
    },
    resetConnection: function () {
      this.connected = false;
      this.pendingConnection = false;
      this.stopRequests = false;
    },
    backendAvailable: function () {
      return typeof window.ethereum !== "undefined";
    },
    validNetwork: function () {
      return window.ethereum.chainId === "0x89";
    },
      hasActiveAccount: function () {
      return this.activeAccount !== "";
    },
    hasError: function () {
      return this.errorMessage !== "";
    },
    hasNotice: function () {
      return this.noticeMessage !== "";
    },
    updateBalance: async function () {
      if (this.connected) {
        this.balance = new Decimal(
          web3js.utils.fromWei(await web3js.eth.getBalance(this.activeAccount))
        );
        console.log("Refreshing balance for " + this.activeAccount);
      }
    },
    unavailable: function () {
      return !(this.backendAvailable() && this.validNetwork());
    },
    shouldAttemptConnection: function () {
      if (this.stopRequests) {
        return false;
      }

      if (this.pendingConnection) {
        return false;
      }

      return true;
    },
    handleConnected: function () {
      // Fresh connections clear the notifications.
      if (this.connected !== true) {
        this.resetNotices();
      }

      this.connected = true;
      this.pendingConnection = false;

      // Notifications must persist for at least 3 seconds.
      if (Date.now() - this.noticeDate > 3000) {
        this.noticeMessage = "";
        this.noticeDate = 0;
      }

      // Errors must persist for at least 3 seconds.
      if (Date.now() - this.errorDate > 3000) {
        this.errorMessage = "";
        this.errorDate = 0;
      }
    },
    formatError: function (err) {},
    handleConnectionFailed: function (error) {
      this.noticeMessage = "";
      this.connected = false;
      this.pendingConnection = false;
      this.stopRequests = true;

      const errorPrefix = "Error " + error.code + ": ";

      if (error.code === 4001) {
        this.setError(errorPrefix + "Access to accounts denied.");
      } else {
        this.setError(errorPrefix + error.message);
      }
    },
    updateAccount: async function () {
      if (this.shouldAttemptConnection()) {
        this.pendingConnection = true;

        try {
          this.accounts = await window.ethereum.request({
            method: "eth_requestAccounts",
          });
          this.handleConnected();

          if (this.accounts.length > 0) {
            this.activeAccount = this.accounts[0];
            this.updateBalance();
          }
        } catch (error) {
          this.handleConnectionFailed(error);
        }
      }
    },
    smartPolygonProvider: function () {
      return {
        chainId: "0x89",
        rpcUrls: [
          "https://polygon-rpc.com/",
        ],
        chainName: "Polygon Mainnet",
        nativeCurrency: {
          name: "Polygon",
          symbol: "MATIC",
          decimals: 18,
        },
        blockExplorerUrls: ["https://polygonscan.com/"],
        iconUrls: ["https://assets.coingecko.com/coins/images/4713/small/matic-token-icon.png?1624446912"],
      };
    },
    attemptMetaMaskProviderRegistration: async function () {
      try {
        await window.ethereum.request({
          method: "wallet_switchEthereumChain",
          params: [{ chainId: "0x89" }],
        });
        return true;
      } catch (switchError) {
        // This error code indicates that the chain has not been added to MetaMask.
        if (switchError.code === 4902) {
          try {
            await window.ethereum.request({
              method: "wallet_addEthereumChain",
              params: [this.smartPolygonProvider()],
            });

            return true;
          } catch (addError) {
            return false;
          }
        }
        return false;
      }
    },
    checkState: async function () {
      this.addBindings();

      if (this.unavailable()) {
        let success = false;

        if (!this.attemptedRegistration) {
          this.attemptedRegistration = true;
          success = await this.attemptMetaMaskProviderRegistration();
        }

        if (success) {
          return;
        }

        this.resetData();
        if (!this.backendAvailable()) {
          this.setError("Please install MetaMask to get started!")
        } else {
          this.setError("Please login to MetaMask and connect to the Polygon network!");
        }

        if (this.bindingRetries < 15) {
          await delay(250);
          this.checkState();
        }

        return;
      }

      this.updateAccount();
    },
    resetData: function () {
      this.accounts = [];
      this.activeAccount = "";
      this.balance = new BigNumber(0);
      this.connected = null;
      this.errorMessage = "";
      this.pendingConnection = null;
      this.sendAmount = new BigNumber(0);
      this.sendContract = "";
      this.sendTo = "";
      this.stopRequests = false;
    },
  },
};
</script>
