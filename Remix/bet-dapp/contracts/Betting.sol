pragma solidity ^0.4.18; // Solidity version


// Betting contract 는 이를 배포하는 소유자(owner)만이 호출할 수 있어야 하므로
// 접근 modifier 를 생성하여 이를 연결시켜야 함
contract Ownable {
    address owner;
    
    // Constructor
    // 해당 생성자가 호출되면 현재 컨트랙트의 생성자 어드레스의 상태가 저장됨
    function Ownable() public {
            owner = msg.sender;
    }

    // 접근 modifier
    // 현재 접근자가 이 컨트랙트의 소유자가 아니면 throw 예외를 보냄, 그렇지 않으면 다음 로직을 처리
    modifier Owned {
        require(msg.sender == owner);
        _;
    }
}

// 해당 컨트랙트를 소멸시킬 수 있는 기능을 가지는 Mortal 컨트랙트
// Ownable 컨트랙트를 상속받음
contract Mortal is Ownable {
    function kill() public Owned { // 접근자로 Owned 가 설정되어 있으므로 해당 컨트랙트의 생성자만이 이를 호출할 수 있음
        selfdestruct(owner); // 컨트랙트가 소멸되고 펀드를 되돌려줌
    }
}

contract Betting is Mortal { // Mortal 컨트랙트를 상속받음
    uint minBet; // 최소 베팅액
    uint winRate; // 배당률(%)

    // Custom Event
    event Won(bool _result, uint _amount); // _result: 해당 베팅의 결괏값, _amount: 최종적으로 받게 될 액수

    // Constructor
    function Betting(uint _minBet, uint _winRate) payable public { // payable: 배포 시 이더를 미리 가져올 수 있게 함
        // parameter validity check
        // require: 해당 조건 만족하지 않을 시 프로세스는 도중에 멈추고 throw 함
        require(_minBet > 0);
        require(_winRate <= 100);

        minBet = _minBet;
        winRate = _winRate;
    }

    // fallback function
    function() public {
        revert(); // 컨트랙트에 직접적인 금액 전송을 막음
    }

    // 실제 베팅이 이루어지는 함수
    function bet(uint _num) payable public { // _num: 베팅하고자 하는 숫자, payable: 실제 이더 전송을 하기 위한 파라미터
        require(_num > 0 && _num <= 5);
        require(msg.value >= minBet); // 전송하는 이더값 msg.value 가 최소 베팅액 minBet 보다 크거나 같아야 함

        // 1~5 랜덤 숫자 생성
        uint winNum = random();
        
        // 유저가 선택한 숫자와 랜덤 숫자가 맞을 경우, 배당률에 따라 받을 액수를 계산
        if(_num == winNum) {
            uint amtWon = msg.value * (100 - winRate)/10; // 배당률에 따라 받을 액수 계산
            if(!msg.sender.send(amtWon)) revert(); // 컨트랙트 호출자(msg.sender)에게 send 함수를 통해 액수 전송, 실패할 경우 revert()
            Won(true, amtWon); // 앞서 정의한 커스텀 이벤트 Won을 성공한 결괏값인 true 와 받게 될 금액 amtWon을 인자로 넘겨 디스패치 함
        } else {
            Won(false, 0);
        }

    }


    // 컨트랙트 소유자가 현재 어드레스의 잔액을 확인할 수 있는 함수
    function getBalance() Owned public view returns (uint) {
        return address(this).balance; // 현재 컨트랙트의 어드레스를 가져와 balance 잔액 반환
    }

    function random() public view returns (uint) {
        // keccak256: 해시함수
        // 현재 블록의 난이도, 블록 넘버, 타임스탬프를 활용하여 해시 변환을 하고, 이를 uint 형태로 타임 변환을 함
        // 이를 통해 나온 랜덤한 숫자에 5로 나눈 나머지 값에 1을 더하여 최종적으로 1~5 사이의 숫자를 반환함
        return uint(keccak256(block.difficulty, block.number, now)) % 5 + 1;
    }
}