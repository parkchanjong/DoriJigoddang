//컨트랙트
module.exports = function(callback) {
  web3.eth.sendTransaction(
    {
      from: web3.eth.accounts[9],
      to: "0x8cAC226B96C051A3c30C85aEC4F9Ac2B80a99653",
      value: web3.toWei(30, "ether")
    },
    callback
  );
};
