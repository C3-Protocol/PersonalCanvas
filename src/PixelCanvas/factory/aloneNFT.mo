/**
 * Module     : aloneNFT.mo
 * Copyright  : 2021 Hellman Team
 * License    : Apache 2.0 with LLVM Exception
 * Maintainer : Hellman Team - Leven
 * Stability  : Experimental
 */

import AloneCanvas "../canvas/aloneCanvas";
import IC0 "../common/IC0";
import WICP "../common/WICP";
import Types "../common/types";
import AloneStorage "../storage/aloneStorage";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Array "mo:base/Array";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Cycles "mo:base/ExperimentalCycles";

/**
 * Factory Canister to Create Canvas Canister
 */
shared(msg)  actor class AloneNFT (owner_: Principal, feeTo_: Principal, wicpCanisterId_: Principal) = this {
    
    type CreateCanvasResponse = Types.CreateCanvasResponse;
    type WICPActor = WICP.WICPActor;
    type TokenIndex = Types.TokenIndex;
    type Balance = Types.Balance;
    type ListRequest = Types.ListRequest;
    type ListResponse = Types.ListResponse;
    type BuyResponse = Types.BuyResponse;
    type Listings = Types.Listings;
    type SoldListings = Types.SoldListings;
    type OpRecord = Types.OpRecord;
    type Operation = Types.Operation;
    type TransferResponse = Types.TransferResponse;
    type MintAloneRequest = Types.MintAloneRequest;
    type MintAloneNFTRequest = Types.MintAloneNFTRequest;
    type CanvasIdentity = Types.CanvasIdentity;
    type StorageActor = Types.AloneStorageActor;
    private stable var cyclesCreateCanvas: Nat = Types.CREATECANVAS_CYCLES;

    private stable var owner: Principal = owner_;
    private stable var dimension: Nat = Types.DIMENSION;
    private stable var createAloneCanvasFee: Nat = Types.CREATEALONECANISTER_FEE;
    private stable var basicOperatePrice: Nat = Types.BASCIOPERATING_PRICE;
    private stable var minDrawNum: Nat = Types.MINDRAWNUM;
    private stable var feeTo: Principal = feeTo_;
    private stable var WICPCanisterActor: WICPActor = actor(Principal.toText(wicpCanisterId_));

    private stable var nextTokenId : TokenIndex  = 0;
    private stable var supply : Balance  = 0;
    private stable var marketFeeRatio : Nat  = 2;
    private stable var storageCanister : ?StorageActor = null;

    private stable var listingsEntries : [(TokenIndex, Listings)] = [];
    private var listings = HashMap.HashMap<TokenIndex, Listings>(1, Types.TokenIndex.equal, Types.TokenIndex.hash);

    private stable var soldListingsEntries : [(TokenIndex, SoldListings)] = [];
    private var soldListings = HashMap.HashMap<TokenIndex, SoldListings>(1, Types.TokenIndex.equal, Types.TokenIndex.hash);

    // Mapping from Canvas Index ID to Canvas-canister ID
    private stable var registryCanvasEntries : [(TokenIndex, Principal)] = [];
    private var registryCanvas = HashMap.HashMap<TokenIndex, Principal>(1, Types.TokenIndex.equal, Types.TokenIndex.hash);

    // Mapping from Canvas-canister ID to Index ID
    private stable var registryCanvasEntries2 : [(Principal, TokenIndex)] = [];
    private var registryCanvas2 = HashMap.HashMap<Principal, TokenIndex>(1, Principal.equal, Principal.hash);

    //Mapping from userPrincipalId - AloneCanisterId Array map
    private stable var userAllAloneCanvasEntries : [(Principal, [(TokenIndex, Principal)])] = [];
    private var userAllAloneCanvas = HashMap.HashMap<Principal, HashMap.HashMap<TokenIndex, Principal>>(1, Principal.equal, Principal.hash);
    
    // Mapping from owner to number of owned token
    private stable var balancesEntries : [(Principal, Nat)] = [];
    private var balances = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);

    // Mapping from NFT canister ID to owner
    private stable var ownersEntries : [(TokenIndex, Principal)] = [];
    private var owners = HashMap.HashMap<TokenIndex, Principal>(1, Types.TokenIndex.equal, Types.TokenIndex.hash); 

    // Mapping from NFT canister ID to approved address
    private var nftApprovals = HashMap.HashMap<TokenIndex, Principal>(1, Types.TokenIndex.equal, Types.TokenIndex.hash); 

    // Mapping from owner to operator approvals
    private var operatorApprovals = HashMap.HashMap<Principal, HashMap.HashMap<Principal, Bool>>(1, Principal.equal, Principal.hash);

    private stable var invitedEntries : [(Principal, Nat)] = [];
    private var invited = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);

    private stable var isOpen : Bool = false;

    system func preupgrade() {
        listingsEntries := Iter.toArray(listings.entries());
        soldListingsEntries := Iter.toArray(soldListings.entries());
        registryCanvasEntries := Iter.toArray(registryCanvas.entries());
        registryCanvasEntries2 := Iter.toArray(registryCanvas2.entries());
        balancesEntries := Iter.toArray(balances.entries());
        ownersEntries := Iter.toArray(owners.entries());
        invitedEntries := Iter.toArray(invited.entries());

        var size1 : Nat = userAllAloneCanvas.size();
        var temp1 : [var (Principal, [(TokenIndex, Principal)])] = Array.init<(Principal, [(TokenIndex, Principal)])>(size1, (owner, []));
        size1 := 0;
        for ((k1, v1) in userAllAloneCanvas.entries()) {
            temp1[size1] := (k1, Iter.toArray(v1.entries()));
            size1 += 1;
        };
        userAllAloneCanvasEntries := Array.freeze(temp1);
    };

    system func postupgrade() {
        balances := HashMap.fromIter<Principal, Nat>(balancesEntries.vals(), 1, Principal.equal, Principal.hash);
        owners := HashMap.fromIter<TokenIndex, Principal>(ownersEntries.vals(), 1, Types.TokenIndex.equal, Types.TokenIndex.hash);
        
        registryCanvas := HashMap.fromIter<TokenIndex, Principal>(registryCanvasEntries.vals(), 1, Types.TokenIndex.equal, Types.TokenIndex.hash);
        registryCanvas2 := HashMap.fromIter<Principal, TokenIndex>(registryCanvasEntries2.vals(), 1, Principal.equal, Principal.hash);
        listings := HashMap.fromIter<TokenIndex, Listings>(listingsEntries.vals(), 1, Types.TokenIndex.equal, Types.TokenIndex.hash);
        soldListings := HashMap.fromIter<TokenIndex, SoldListings>(soldListingsEntries.vals(), 1, Types.TokenIndex.equal, Types.TokenIndex.hash);
        invited := HashMap.fromIter<Principal, Nat>(invitedEntries.vals(), 1, Principal.equal, Principal.hash);

        listingsEntries := [];
        soldListingsEntries := [];
        balancesEntries := [];
        ownersEntries := [];
        registryCanvasEntries := [];
        registryCanvasEntries2 := [];
        invitedEntries := [];

        for ((k1, v1) in userAllAloneCanvasEntries.vals()) {
            let alone_temp = HashMap.fromIter<TokenIndex, Principal>(v1.vals(), 1, Types.TokenIndex.equal, Types.TokenIndex.hash);
            userAllAloneCanvas.put(k1, alone_temp);
        };
        userAllAloneCanvasEntries := [];
    };

    public shared(msg) func setStorageCanisterId(storage: ?Principal) : async Bool {
        assert(msg.caller == owner);
        if (storage == null) { storageCanister := null; }
        else { storageCanister := ?actor(Principal.toText(Option.unwrap(storage))); };
        return true;
    };

    public query func getStorageCanisterId() : async ?Principal {
        var ret: ?Principal = null;
        if(storageCanister != null){
            ret := ?Principal.fromActor(Option.unwrap(storageCanister));
        };
        ret
    };

    public shared(msg) func newStorageCanister(owner: Principal) : async Bool {
        assert(msg.caller == owner and storageCanister == null);
        Cycles.add(cyclesCreateCanvas);
        let storage = await AloneStorage.AloneStorage(owner);
        storageCanister := ?storage;
        return true;
    };

    //create alone-draw Canvas Canister
    public shared(msg) func mintAloneCanvas(request: MintAloneRequest) : async CreateCanvasResponse {
        let remainTimes = _checkInvited(msg.caller);
        if( (not isOpen) or (remainTimes > 0) ){
            return #err(#NotBeInvited);
        };
        if(not _checkCyclesEnough()){
            return #err(#InsufficientCycles);
        };
        if(not _checkCallerCanvas(msg.caller)){
            return #err(#ExceedMaxNum);
        };
        //dudect usr's WICP when create new AllonePixelCanvas
        if(remainTimes == 0){
            let transferResult = await WICPCanisterActor.transferFrom(msg.caller, feeTo, createAloneCanvasFee);
            switch(transferResult){
                case(#ok(b)) {};
                case(#err(errText)){
                    return #err(errText);
                };
            };
        };
        //create new PixelCanvas and use the result canisterId to modify the member vaiable 
        Cycles.add(cyclesCreateCanvas);
        let mintRequest: MintAloneNFTRequest = {
            name = request.name;
            desc = request.desc;
            createFee = createAloneCanvasFee;
            owner = owner;
            createUser = msg.caller;
            feeTo = feeTo;
            wicpCanisterId = Principal.fromActor(WICPCanisterActor);
            tokenIndex = nextTokenId;
            dimension = dimension;
            basePrice = basicOperatePrice;
            minDrawNum = minDrawNum;
            backGround = request.backGround;
        };
        let newCanvas = await AloneCanvas.AloneCanvas(mintRequest);
        let canvasCid = Principal.fromActor(newCanvas);
        let info: CanvasIdentity = { 
            index=nextTokenId; 
            canisterId=canvasCid;
        };
        _addAloneCanvas(canvasCid, msg.caller);
        _addCanvas(canvasCid);
        if(remainTimes > 0){_subAccRemainTimes(msg.caller);};
        ignore _setController(canvasCid);
        return #ok(info);
    };

    public shared(msg) func setController(canisterId: Principal): async Bool {
        assert(msg.caller == owner);
        assert(Option.isSome(registryCanvas2.get(canisterId)));
        await _setController(canisterId);
        return true;
    };

    public shared(msg) func setFavorite(info: CanvasIdentity): async Bool {
        assert(Option.isSome(registryCanvas.get(info.index))
                and Option.unwrap(registryCanvas.get(info.index)) == info.canisterId);
        if(storageCanister != null){
            ignore Option.unwrap(storageCanister).setFavorite(msg.caller, info);
        };
        return true;
    };

    public shared(msg) func cancelFavorite(info: CanvasIdentity): async Bool {
        assert(Option.isSome(registryCanvas.get(info.index))
                and Option.unwrap(registryCanvas.get(info.index)) == info.canisterId);

        if(storageCanister != null){
            ignore Option.unwrap(storageCanister).cancelFavorite(msg.caller, info);
        };
        return true;
    };

    public shared(msg) func getCanvasStatus(canisterId: Principal): async IC0.CanisterStatus {
        assert(Option.isSome(registryCanvas2.get(canisterId)));
        let param: IC0.CanisterId = {
            canister_id = canisterId;
        };
        let status = await IC0.IC.canister_status(param);
        return status;
    };

    //modify the PixelCanvas NFT to newOwner's map when oldOwner sell the NFT to another
    public shared(msg) func transferFrom(from: Principal, to: Principal, tokenIndex: TokenIndex): async TransferResponse {
        if(Option.isSome(listings.get(tokenIndex))){
            return #err(#ListOnMarketPlace);
        };
        if( not _isApprovedOrOwner(from, msg.caller, tokenIndex) ){
            return #err(#NotOwnerOrNotApprove);
        };
        if(from == to){
            return #err(#NotAllowTransferToSelf);
        };
        _transfer(from, to, tokenIndex);
        if(Option.isSome(listings.get(tokenIndex))){
            listings.delete(tokenIndex);
        };
        return #ok(tokenIndex);
    };

    public shared(msg) func approve(approve: Principal, tokenIndex: TokenIndex): async Bool{
        assert(Option.isSome(_ownerOf(tokenIndex)) 
                and msg.caller == Option.unwrap(_ownerOf(tokenIndex)));
        nftApprovals.put(tokenIndex, approve);
        return true;
    };

    public shared(msg) func setApprovalForAll(operatored: Principal, approved: Bool): async Bool{
        assert(msg.caller != operatored);
        switch(operatorApprovals.get(msg.caller)){
            case(?op){
                op.put(operatored, approved);
                operatorApprovals.put(msg.caller, op);
            };
            case _ {
                var temp = HashMap.HashMap<Principal, Bool>(1, Principal.equal, Principal.hash);
                temp.put(operatored, approved);
                operatorApprovals.put(msg.caller, temp);
            };
        };
        return true;
    };

    public shared(msg) func setAloneFee(createAloneFee: Nat) : async Bool {
        assert(msg.caller == owner);
        createAloneCanvasFee := createAloneFee;
        return true;
    };

    public shared(msg) func setInvited(user: [Principal]) : async Bool {
        assert(msg.caller == owner);
        for(u in user.vals()){
            invited.put(u, 1);
        };
        return true;
    };
    
    public shared(msg) func setMarketFeeRatio(newRatio: Nat) : async Bool {
        assert(msg.caller == owner and newRatio > 0 and newRatio < 100);
        marketFeeRatio := newRatio;
        return true;
    };

    public shared(msg) func setFeeTo(newFeeTo: Principal) : async Bool {
        assert(msg.caller == owner);
        feeTo := newFeeTo;
        return true;
    };

    public shared(msg) func setCreateCycles(cycles: Nat) : async Bool {
        assert(msg.caller == owner);
        cyclesCreateCanvas := cycles;
        return true;
    };

    public shared(msg) func setOpen(bOpen: Bool) : async Bool {
        assert(msg.caller == owner);
        isOpen := bOpen;
        return bOpen;
    };

    public shared(msg) func setBasicPrice(newBasicPrice: Nat) : async Bool {
        assert(msg.caller == owner);
        basicOperatePrice := newBasicPrice;
        return true;
    };

    public shared(msg) func setMinDrawNum(newNum: Nat) : async Bool {
        assert(msg.caller == owner);
        minDrawNum := newNum;
        return true;
    };

    public shared(msg) func setWICPCanisterId(wicpCanisterId: Principal) : async Bool {
        assert(msg.caller == owner);
        WICPCanisterActor := actor(Principal.toText(wicpCanisterId));
        return true;
    };

    public shared(msg) func setOwner(newOwner: Principal) : async Bool {
        assert(msg.caller == owner);
        owner := newOwner;
        return true;
    };

    public shared(msg) func setDimension(newDimension: Nat) : async Bool {
        assert(msg.caller == owner);
        dimension := newDimension;
        return true;
    };

    public shared(msg) func wallet_receive() : async Nat {
        let available = Cycles.available();
        let accepted = Cycles.accept(available);
        return accepted;
    };

    public query func getApproved(tokenIndex: TokenIndex) : async ?Principal {
        nftApprovals.get(tokenIndex)
    };

    public query func getOwner() : async Principal {
        owner
    };

    public query func getAloneFee() : async Nat {
        createAloneCanvasFee
    };

    public query func getFeeTo() : async Principal {
        feeTo
    };

    public query func getCreateCycles() : async Nat {
        cyclesCreateCanvas
    };

    public query func getBasicPrice() : async Nat {
        basicOperatePrice
    };

    public query func getMinDrawNum() : async Nat {
        minDrawNum
    };

    public query func isApprovedForAll(owner: Principal, operatored: Principal) : async Bool {
        _checkApprovedForAll(owner, operatored)
    };

    public query func ownerOf(tokenIndex: TokenIndex) : async ?Principal {
        _ownerOf(tokenIndex)
    };

    public query func balanceOf(user: Principal) : async Nat {
        _balanceOf(user)
    };

    public query func getCycles() : async Nat {
        return Cycles.balance();
    };

    public query func getWICPCanisterId() : async Principal {
        Principal.fromActor(WICPCanisterActor)
    };

    public query func getNFTByIndex(index: TokenIndex) : async ?Principal {
        registryCanvas.get(index)
    };

    public query func getInvited(user: Principal) : async Nat {
        _checkInvited(user)
    };

    public query func getAllNFT(user: Principal) : async [(TokenIndex, Principal)] {
        var ret: [(TokenIndex, Principal)] = [];
        for((k,v) in owners.entries()){
            if(v == user){
                ret := Array.append(ret, [ (k, Option.unwrap(registryCanvas.get(k))) ] );
            };
        };
        return ret;
    };

    public query func getAllAloneCanvas(user: Principal) : async [(TokenIndex, Principal)] {
        var ret: [(TokenIndex, Principal)] = [];
        if(Option.isNull(userAllAloneCanvas.get(user))){
            return ret;
        };
        let aloneArr = Iter.toArray(Option.unwrap(userAllAloneCanvas.get(user)).entries());
        let arr = Array.sort(aloneArr, Types.compare);
        return arr;
    };

    private func _checkInvited(user: Principal) : Nat {
        var ret: Nat = 0;
        if(Option.isSome(invited.get(user))){ ret := Option.unwrap(invited.get(user)); };
        return ret;
    };

    private func _subAccRemainTimes(user: Principal) {
        switch(invited.get(user)){
            case (?r){
                if( r == 1 ){
                    invited.delete(user);
                }else if(r > 1){
                    invited.put(user, r - 1);
                };
            };
            case _ {};
        }
    };

    private func _balanceOf(owner: Principal): Nat {
        var balance: Nat = 0;
        if(Option.isSome(balances.get(owner))){
            balance := Option.unwrap(balances.get(owner));
        };
        balance
    };

    private func _transfer(from: Principal, to: Principal, tokenIndex: TokenIndex) {
        balances.put( from, _balanceOf(from) - 1 );
        balances.put( to, _balanceOf(to) + 1 );
        nftApprovals.delete(tokenIndex);
        owners.put(tokenIndex, to);
    };

    private func _addSoldListings( orderInfo :Listings) {
        switch(soldListings.get(orderInfo.tokenIndex)){
            case (?sold){
                let newDeal = {
                    lastPrice = orderInfo.price;
                    time = orderInfo.time;
                    account = sold.account + 1;
                };
                soldListings.put(orderInfo.tokenIndex, newDeal);
            };
            case _ {
                let newDeal = {
                    lastPrice = orderInfo.price;
                    time = orderInfo.time;
                    account = 1;
                };
                soldListings.put(orderInfo.tokenIndex, newDeal);
            };
        };
    };

    private func _ownerOf(tokenIndex: TokenIndex) : ?Principal {
        owners.get(tokenIndex)
    };

    private func _checkOwner(tokenIndex: TokenIndex, from: Principal) : Bool {
        
        Option.isSome(owners.get(tokenIndex)) and 
        Option.unwrap(owners.get(tokenIndex)) == from
    };

    private func _checkApprove(tokenIndex: TokenIndex, approved: Principal) : Bool {
        Option.isSome(nftApprovals.get(tokenIndex)) and 
        Option.unwrap(nftApprovals.get(tokenIndex)) == approved
    };

    private func _checkApprovedForAll(owner: Principal, operatored: Principal) : Bool {
        var ret: Bool = false;
        let opAppoveMap = operatorApprovals.get(owner);
        if(Option.isNull(opAppoveMap)){ return ret; };
        let approve =  Option.unwrap(opAppoveMap).get(operatored);
        if(Option.isNull(approve)){ return ret; };
        return Option.unwrap(approve);
    };

    private func _isApprovedOrOwner(from: Principal, spender: Principal, tokenIndex: TokenIndex) : Bool {
        _checkOwner(tokenIndex, from) and (_checkOwner(tokenIndex, spender) or 
        _checkApprove(tokenIndex, spender) or _checkApprovedForAll(from, spender))
    };

    private func _setController(canisterId: Principal): async () {

        let controllers: ?[Principal] = ?[owner, Principal.fromActor(this)];
        let settings: IC0.CanisterSettings = {
            controllers = controllers;
            compute_allocation = null;
            memory_allocation = null;
            freezing_threshold = null;
        };
        let params: IC0.UpdateSettingsParams = {
            canister_id = canisterId;
            settings = settings;
        };
        await IC0.IC.update_settings(params);
    };

    private func _addCanvas(canvasId: Principal) {
        registryCanvas.put(nextTokenId, canvasId);
        registryCanvas2.put(canvasId, nextTokenId);
        supply := supply + 1;
        nextTokenId := nextTokenId + 1;
    };

    private func _addAloneCanvas(canvasId: Principal, owner: Principal) {
        switch(userAllAloneCanvas.get(owner)){
            case(?aloneMap){
                aloneMap.put(nextTokenId, canvasId);
                userAllAloneCanvas.put(owner, aloneMap);
            };
            case _ {
                var temp = HashMap.HashMap<TokenIndex, Principal>(1, Types.TokenIndex.equal, Types.TokenIndex.hash);
                temp.put(nextTokenId, canvasId);
                userAllAloneCanvas.put(owner, temp);
            };
        };
    };

    private func _removeCanisterFromAlone(nftOwner: Principal, tokenIndex: TokenIndex) {
        switch(userAllAloneCanvas.get(nftOwner)){
            case (?aloneMap){
                aloneMap.delete(tokenIndex);
                if(aloneMap.size() == 0) { userAllAloneCanvas.delete(nftOwner); }
                else { userAllAloneCanvas.put(nftOwner, aloneMap); };
            };
            case _ {};
        };
    };

    private func _checkCyclesEnough() : Bool {
        var ret: Bool = false;
        let balance = Cycles.balance();
        if(balance > 2 * cyclesCreateCanvas){
            ret := true;
        };
        ret
    };

    private func _checkCallerCanvas(user: Principal) : Bool {
        var num: Nat = 0;
        var ret: Bool = false;
        switch(userAllAloneCanvas.get(user)){
            case (?m) {
                num := m.size();
            };
            case _ {};
        };
        if(num < 3){ ret := true; };
        return ret;
    };
}
