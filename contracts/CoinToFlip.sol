pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// CoinToFlip.sol
// Simple Coin flip game
//
// Educational purpose only.
// ----------------------------------------------------------------------------
contract CoinToFlip {

    uint constant MAX_CASE = 2; // for coin
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_BET = 10 ether;
    uint constant HOUSE_FEE_PERCENT = 5;
    uint constant HOUSE_MIN_FEE = 0.005 ether;

    address public owner;   //계정 타입 -계정 주소만들때
    uint public lockedInBets;

    struct Bet {    //베팅정보-구조체
        uint amount;
        uint8 numOfBetBit;// 중복 베팅금지
        uint placeBlockNumber; // Block number of Bet tx.
        // Bit mask representing winning bet outcomes
        // 0000 0010 for front side of coin, 50% chance
        // 0000 0001 for back side of coin, 50% chance
        // 0000 0011 for both sides,  100% chance - no reward!
        uint8 mask;//경우의수 2개 앞뒤
        address gambler; // Address of a gambler, used to pay out winning bets.
    }

    mapping (address => Bet) bets; //Bet book  데이터 타입
    //플레이어 베팅 정보 장부에 기록

    event Reveal(uint reveal);//1앞 or 2뒤          이벤트가 있어야 화면으로 전달 ->emit
    event Payment(address indexed beneficiary, uint amount);
    event FailedPayment(address indexed beneficiary, uint amount);


    constructor () public {
        owner = msg.sender;// 배포계정
    }

    // Standard modifier on methods invokable only by contract owner.
    modifier onlyOwner {
        require (msg.sender == owner, "Only owner can call this function.");
        _;
    }//modifier-> 배포자만 실행할수 있는 함수 검사


    // Funds withdrawal to maintain the house
    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount + lockedInBets <= address(this).balance, "larger than balance.");
        sendFunds(beneficiary, withdrawAmount);
    }//이더인출

    function sendFunds(address beneficiary, uint amount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, amount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }//상금제공


    function kill() external onlyOwner {
        require (lockedInBets == 0, "All bets should be processed before self-destruct.");
        selfdestruct(owner);
    }//컨트렉트 비활성화  -> 관리자만 가능하게


    function () public payable {}// 폴백->하우스 초기 자금


    //Bet by player  뭐 베팅했는지만 
    function placeBet(uint8 betMask) external payable {

        uint amount = msg.value;

        require (amount >= MIN_BET && amount <= MAX_BET, "Amount is out of range.");
        require (betMask > 0 && betMask < 256, "Mask should be 8 bit");

        Bet storage bet = bets[msg.sender]; //mapping bets(address => Bet) 플레이어 장부에서 찾기 없으면 만들기
        //Bet bet = bets[msg.sender];

        require (bet.gambler == address(0), "Bet should be empty state."); //can place a bet
        //if (bet.gambler == null) X 

        //count bet bit in the betMask
        //0000 0011  number of bits = 2
        //0000 0001  number of bits = 1
        uint8 numOfBetBit = countBits(betMask);

        bet.amount = amount;
        bet.numOfBetBit = numOfBetBit;
        bet.placeBlockNumber = block.number;
        bet.mask = betMask;
        bet.gambler = msg.sender;

        // need to lock possible winning amount to pay
        uint possibleWinningAmount = getWinningAmount(amount, numOfBetBit);
        lockedInBets += possibleWinningAmount;

        // Check whether house has enough ETH to pay the bet.
        require(lockedInBets < address(this).balance, "Cannot afford to pay the bet.");//내돈보다 플레이어 돈많으면 베팅안되게
    }

    function getWinningAmount(uint amount, uint8 numOfBetBit) private pure returns (uint winningAmount) {

        require (0 < numOfBetBit && numOfBetBit < MAX_CASE, "Probability is out of range"); // 1

        uint houseFee = amount * HOUSE_FEE_PERCENT / 100;

        if (houseFee < HOUSE_MIN_FEE) {
            houseFee = HOUSE_MIN_FEE;
        }//보상

        //reward calculation is depends on your own idea
        uint reward = amount / (MAX_CASE + (numOfBetBit-1));

        winningAmount = (amount - houseFee) + reward;
    }

    //
    //
    //
    //Reveal the coin by player  결과
    function revealResult(uint8 seed) external {

        Bet storage bet = bets[msg.sender];
        uint amount = bet.amount;
        uint8 numOfBetBit = bet.numOfBetBit;
        uint placeBlockNumber = bet.placeBlockNumber;
        address gambler = bet.gambler;

        require (amount > 0, "Bet should be in an 'active' state");

        // should be called after placeBet
        require(block.number > placeBlockNumber, "revealResult in the same block as placeBet, or before.");
        //베팅을 결과보다 먼저 블록에 저장
        //RNG(Random Number Generator)난수생성 블록해시(블록체인 식별번호 이용해 난수생성)
        bytes32 random = keccak256(abi.encodePacked(blockhash(block.number-seed), blockhash(placeBlockNumber)));

        uint reveal = uint(random) % MAX_CASE; // 0 or 1

        uint winningAmount = 0;
        uint possibleWinningAmount = 0;
        possibleWinningAmount = getWinningAmount(amount, numOfBetBit);

        if ((2 ** reveal) & bet.mask != 0) {
            winningAmount = possibleWinningAmount;
        }

        emit Reveal(2 ** reveal);

        if (winningAmount > 0) {
            sendFunds(gambler, winningAmount);//상금전송
        }

        lockedInBets -= possibleWinningAmount;
        clearBet(msg.sender);
    }

    //베팅정보 초기화
    function clearBet(address player) private {
        Bet storage bet = bets[player];

        bet.amount = 0;
        bet.numOfBetBit = 0;
        bet.placeBlockNumber = 0;
        bet.mask = 0;
        bet.gambler = address(0); // NULL
    }



    //can refund before reveal
    function refundBet() external {//만약 베팅후 취소하는것-> 수수료는 가져온다

        // Check that bet has been already mined.
        require(block.number > bet.placeBlockNumber, "refundBet in the same block as placeBet, or before.");

        Bet storage bet = bets[msg.sender];
        uint amount = bet.amount;

        require (amount > 0, "Bet should be in an 'active' state");

        uint8 numOfBetBit = bet.numOfBetBit;

        // Send the refund.
        sendFunds(bet.gambler, amount);

        uint possibleWinningAmount;
        possibleWinningAmount = getWinningAmount(amount, numOfBetBit);

        lockedInBets -= possibleWinningAmount;
        clearBet(msg.sender);
    }


    function checkHouseFund() public view onlyOwner returns(uint) {
        return address(this).balance;
    }//잔액확인


    function countBits(uint8 _num) internal pure returns (uint8){
        uint8 count; 
        while (_num > 0){
            count += _num & 1;
            _num >>= 1;
        }
        return count;
    }


}