//메타마스크 계정
module.exports = function(callback) {
  web3.eth.sendTransaction(
    {
      from: web3.eth.accounts[9],
      to: "0xC6f86F45FfFB8B49208835A3Ef4D35bf931c3F86",
      value: web3.toWei(30, "ether")
    },
    callback
  );
};
