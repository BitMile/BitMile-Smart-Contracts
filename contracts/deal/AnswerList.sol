pragma solidity ^0.4.20;


import "./DealInfo.sol";
import "../ownership/Ownable.sol";

contract AnswerList is DealInfo, Ownable {
  struct Answer {
    address userId;
    string yesNoAnswer;
    string encDocId;
  }
    
  // dealId => answers list
  mapping(uint256 => Answer[]) answers;   
    
  function addAnswer(uint256 _dealId, address _userId, string _yesNoAnswer, string _encDocId) public onlyOwner {
    DealData storage _deal = deals[_dealId];
        
    require(_deal.id == _dealId);
        
    Answer memory _answer;
    _answer.userId = _userId;
    _answer.yesNoAnswer = _yesNoAnswer;
    _answer.encDocId = _encDocId;
        
    answers[_dealId].push(_answer);
  }
       
  function getAnswer(uint256 _dealId, uint256 _index) public view returns(
    address userId,
    string answer,
    string encDocId
  ) {
    DealData storage _deal = deals[_dealId];
        
    require(_deal.bidder == msg.sender);
    require(_index < answers[_dealId].length);
        
    Answer memory _answer = answers[_dealId][_index];
    return (
      _answer.userId,
      _answer.yesNoAnswer,
      _answer.encDocId
    );
  }

  function getTheNumberOfAnswers(uint256 _dealId) public view returns(uint256) {
    require(deals[_dealId].id == _dealId);
        
    return answers[_dealId].length;
  }

  function clearAnswers(uint256 _dealId) public payable {
    require(deals[_dealId].bidder == msg.sender);
        
    delete answers[_dealId];
  }  
}

