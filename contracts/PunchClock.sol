pragma solidity ^0.4.4;

contract PunchClock {
    // the owner of the contract
    address owner;

    // The data structure to store the time in and out of a person
    struct PunchCard {
        uint timeIn; // time the person gets in, unix timestamp
        uint timeOut; // time the person gets out, unix timestamp
    }

    // The list of all admins. The reason for having these two mapping is that
    // it's not possible to iterate through the list of keys in a mapping,
    // so the workaround is to have two mapping, with the second mapping is basically
    // just a map by index so that we can get all the keys. Similarly, it's not
    // possible to iterate through a mapping, so the workaround is to keep track
    // of the size manually.
    mapping(address => bool) admins;
    mapping(uint => address) adminsByIndex;
    uint totalNumberOfAdmins;

    // The list of all members.
    mapping(address => bool) members;
    mapping(uint => address) membersByIndex;
    uint totalNumberOfMembers;

    // All punch cards of all members
    mapping(address => PunchCard[]) punchClock;

    // Constructor, create a new punch clock and assign the creator as the owner of the punch clock
    function PunchClock() {
        owner = msg.sender;
        admins[owner] = true;
        adminsByIndex[0] = owner;
        totalNumberOfAdmins = 1;
        members[owner] = true;
        membersByIndex[0] = owner;
        totalNumberOfMembers = 1;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }
    modifier onlyAdmins() {
        if (admins[msg.sender] == false) throw;
        _;
    }
    modifier onlyMembers() {
        if (members[msg.sender] == false) throw;
        _;
    }

    // Add a member to the contract if the member does not already exist
    function addMemberInternal(address member) internal {
        if (members[member] == false) {
            var newMemberIndex = totalNumberOfMembers;
            members[member] = true;
            membersByIndex[newMemberIndex] = member;
            totalNumberOfMembers++;
        }
    }
    // Add a new admin. Only the owner can perform this task.
    function addAdmin(address admin) onlyOwner {
        if (admins[admin] == false) {
            var indexOfNewAdmin = totalNumberOfAdmins;
            admins[admin] = true;
            adminsByIndex[indexOfNewAdmin] = admin;
            totalNumberOfAdmins++;

            addMemberInternal(admin);
        }
    }

    // Add a new member to the list of member. Only admins can perform this task
    function addMember(address member) onlyAdmins {
        addMemberInternal(member);
    }

    // Return all punch cards of a member
    function getPunchCardsInternal(address member) constant internal returns(uint[2][]) {
        var allCards = punchClock[member];
        uint[2][] memory tmp = new uint[2][](allCards.length);
        for (uint i = 0; i < allCards.length; i++) {
            tmp[i] = [allCards[i].timeIn, allCards[i].timeOut];
        }
        return tmp;
    }

    // Return all punch cards of the requestor. Only member can perform this task
    function getMyPunchCards() onlyMembers constant returns(uint[2][] punchCards) {
        return getPunchCardsInternal(msg.sender);
    }

    // Return all punch cards of a member. Only admin can perform this task
    function getPunchCardsOf(address member) onlyAdmins constant returns(uint[2][] punchcards) {
        return getPunchCardsInternal(member);
    }

    // Return all members in the contract. Only admins can perform this task.
    function getAllMembers() onlyAdmins constant returns(address[]) {
        address[] memory allMembers = new address[](totalNumberOfMembers);
        for (uint i = 0; i < totalNumberOfMembers; i++) {
            allMembers[i] = membersByIndex[i];
        }
        return allMembers;
    }

    // Return all admins in the contract. Only owner can perform this task.
    function getAllAdmins() onlyOwner constant returns(address[]) {
        address[] memory allAdmins = new address[](totalNumberOfAdmins);
        for (uint i = 0; i < totalNumberOfAdmins; i++) {
            allAdmins[i] = adminsByIndex[i];
        }
        return allAdmins;
    }

    // Return the owner of the contract. Anyone can perform this task.
    function getOwner() constant returns(address) {
        return owner;
    }

    // Helper function to get the last element in an array
    function getLast(PunchCard[] punchCards) constant internal returns(PunchCard) {
        return punchCards[punchCards.length - 1];
    }

    // Register an in time for a member. Only admins can perform this task.
    function punchIn(address member, uint inTime) onlyAdmins {
        // If the member does not exist, throw
        if (members[member] == false) throw;

        var allCards = punchClock[member];
        if (allCards.length > 0) {
            var lastCard = getLast(allCards);
            if (lastCard.timeOut == 0) {
                // remove the last card if it's incomplete. We'll replace it with a new one.
                punchClock[member].length = punchClock[member].length - 1;
            }
        }

        punchClock[member].push(
            PunchCard({
            timeIn: inTime,
            timeOut: 0
        })
        );
    }

    // Register an out time for a member. Only admins can perform this task.
    function punchOut(address member, uint outTime) onlyAdmins {
        // If the member does not exist, throw
        if (members[member] == false) throw;

        var allCards = punchClock[member];
        if (allCards.length == 0) throw;
        var lastCard = getLast(allCards);
        if (lastCard.timeOut != 0) throw;
        // Remove the last card and replace it with a new one
        punchClock[member].length = punchClock[member].length - 1;
        //lastCard.timeOut = outTime;
        punchClock[member].push(
            PunchCard({
            timeIn: lastCard.timeIn,
            timeOut: outTime
        })
        );
    }

    // Remove an admin. Only owner can perform this task.
    function removeAdmin(address admin) onlyOwner {
        if (admins[admin] == true) {
            admins[admin] = false;
            members[admin] = false;
        }
    }

    // Remove a member. Only admin can perform this task.
    function removeMember(address member) onlyAdmins {
        if (members[member] == true) {
            members[member] = false;
        }
    }

    // Check if a certain person is a member
    function isMember(address person) constant returns(bool) {
        return members[person];
    }

    // Check if a certain person is an admin
    function isAdmin(address person) constant returns(bool) {
        return admins[person];
    }

    // Kill the contract
    function destroy() onlyOwner {
        suicide(owner);
    }

    // TODO: change owner
    // TODO: publish events

    // TODO: batch adding
    // function addAdmins(address[] admins) onlyOwner
    // function addMembers(address[] members) onlyAdmins

    // TODO: batch punching
    //  function batchPunchIn(address[] members,  uint[] inTimes) onlyAdmins
    //  function batchPunchOut(address[] members,  uint[] outTimes) onlyAdmins
}
