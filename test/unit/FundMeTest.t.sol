//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;

    address USER = makeAddr("user");//
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;//

    function setUp() external {
        //us-> FundMeTest ->FundMe 
         DeployFundMe deployfundme = new DeployFundMe();
         fundMe = deployfundme.run();
         vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(),5e18);
    }

    function testIsMsgSender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(),msg.sender);
    }

    function testPriceFeed() public {
        uint256 version = fundMe.getVersion();
        if(version == 4)
        {
            console.log("Price feed version",version);
        assertEq(version,4);
        }
        else if(version == 6)
        {
            console.log("Price feed version",version);
        assertEq(version,6);
        }
    }
    
    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();//hey, the next line should be false , for this expectRevert
        //assert(this tx fails/reverts)
        fundMe.fund();
    }

    function testFundUpdatsFundedDataStructure() public{
        vm.prank(USER);//the next tx will be sent by user
        
        fundMe.fund{value: SEND_VALUE}();//this is func call ,by which you can send eth with the specified {value: 10e18}
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);

        console.log(msg.sender,"<-msg.sender");
        console.log(address(this),"<-address(this)");
        console.log("user starting amount",STARTING_BALANCE);

        assertEq(amountFunded,SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded{
        vm.prank(USER);
        //fundMe.fund{value:SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder,USER);
    } 

    modifier funded{
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{

        vm.prank(USER);
        //fundMe.fund{value: SEND_VALUE}();//->use the modifier intstead

        vm.expectRevert();//we set it beco'z we wanna check the next line should be false
       // vm.prank(USER);//USER here, is not the owner of the fundMe contract , so USER should not be able to withdraw --> a false line
        fundMe.withdraw();//if upper line passes we will pass the withdraw function 

        console.log(fundMe.getOwner());
        console.log(address(this));
        console.log(USER);
    }
    
    function testWithDrawWithSingleFunder() public funded{
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;//->this is the balance of the contarct Owner/Deployer
        uint256 startingFundMeBalance = address(fundMe).balance;//->This is the balance of the contact before withdrawal

        //Act
        vm.prank(fundMe.getOwner());//the next tx will be done by funMe owner
        fundMe.withdraw();//then we withdraw all the funds

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance,0);//fundMe contract should have 0 balance bco'z the owner withdraw all the funds
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);//we  check the balance of the owner's address
    }
    
    function testWithdrawFromMultipleFunders() public funded{
        //Arrange
        uint160 numberOfFunder = 10;//using uint160 because addresses are 160-bit values
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i<numberOfFunder; i++)//Loop to simulate multiple funders contributing to the FundMe contract.
        {
            //hoax = prank(spoofing a sender) + deal(giving it ETH)
            hoax(address(i),SEND_VALUE);//This sets up address(i) with ETH and makes it send `SEND_VALUE` to the contract.
            //fund the fundMe

            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;//->this is the balance of the contarct Owner/Deployer
        uint256 startingFundMeBalance = address(fundMe).balance;//->This is the balance of the contact itself(fundMe)

        //Act
        vm.startPrank(fundMe.getOwner());//Start simulating transactions as the contract owner
        fundMe.withdraw();//withdrawing all the funds
        vm.stopPrank();//Stop the simulated transaction context

        //Assert
        assert(address(fundMe).balance == 0);//fundMe contract should have 0 balance
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFunders_Cheaper() public funded{
        //Arrange
        uint160 numberOfFunder = 10;
        uint160 startingFunderIndex = 1;

        for(uint160 i = startingFunderIndex; i<numberOfFunder; i++)
        {
            
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithDraw();//using a diif withdraw function
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}