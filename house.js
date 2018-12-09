//컨트랙트
module.exports = function(callback) {
  web3.eth.sendTransaction(
    {
      from: web3.eth.accounts[1],
      to: "0xD36Ee5339c4060809F6A5308538D8EF487FEdc6f",
      value: web3.toWei(30, "ether")
    },
    callback
  );
};
