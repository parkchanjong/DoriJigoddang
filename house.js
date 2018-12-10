//컨트랙트
module.exports = function(callback) {
  web3.eth.sendTransaction(
    {
      from: web3.eth.accounts[9],
      to: "0x8b9a9231f71b2863cafcdc0f76648b1e73389c51",
      value: web3.toWei(30, "ether")
    },
    callback
  );
};
