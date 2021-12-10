/**
 * Module     : aloneCanvas.mo
 * Copyright  : 2021 Hellman Team
 * License    : Apache 2.0 with LLVM Exception
 * Maintainer : Hellman Team - Leven
 * Stability  : Experimental
 */
 
import HashMap "mo:base/HashMap";
import Random "mo:base/Random";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Bool "mo:base/Bool";
import Cycles "mo:base/ExperimentalCycles";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Types "../common/types";
import WICP "../common/WICP";
import Factory "../common/factoryActor";

shared(msg) actor class AloneCanvas(_request: Types.MintAloneNFTRequest) = this {
    
    type Position = Types.Position;
    type DrawPosRequest = Types.DrawPosRequest;
    type AloneNFTDesInfo = Types.AloneNFTDesInfo;
    type Color = Types.Color;
    type Result<T,E> = Result.Result<T,E>;
    type DrawResponse = Types.DrawResponse;
    type DrawOverResponse = Types.DrawOverResponse;
    type WICPActor = WICP.WICPActor;
    type FactoryActor = Factory.FactoryActor;

    private stable var request: Types.MintAloneNFTRequest = _request;
    private stable var totalWorth: Nat = request.createFee;
    private stable var changeTotal: Nat = 0;
    private stable var isNFTOver: Bool = false;
    private stable var lastUpdate: Time.Time = Time.now();
    private stable var WICPCanisterActor: WICPActor = actor(Principal.toText(request.wicpCanisterId));
    private stable var FactoryCanisterActor: FactoryActor = actor(Principal.toText(msg.caller));

    private stable var positionState : [(Position, Color)] = [];
    private var positionMap : HashMap.HashMap<Position, Color> = HashMap.fromIter(positionState.vals(), 0, Types.equal, Types.hash);

    system func preupgrade() {
        positionState := Iter.toArray(positionMap.entries());
    };

    system func postupgrade() {
        positionState := [];
    };

    //draw some Pixel color
    public shared(msg) func drawPixel(drawPosReqArray: [DrawPosRequest]): async DrawResponse {
        
        assert(msg.caller == request.createUser and (not isNFTOver) and _checkPosition(drawPosReqArray));
        var totalFee: Nat = request.basePrice * drawPosReqArray.size();
        let transferResult = await WICPCanisterActor.transferFrom(msg.caller, request.feeTo, totalFee);
        switch(transferResult){
            case(#ok(b)) {};
            case(#err(errText)){
                return #err(errText);
            };
        };

        for(i in Iter.fromArray(drawPosReqArray)) {
            positionMap.put(i.pos, i.color);
        };
        totalWorth := totalWorth + totalFee;
        changeTotal := changeTotal + drawPosReqArray.size();
        #ok(true)
    };

    public shared(msg) func drawOver(): async DrawOverResponse {
        if(msg.caller != request.createUser){
            return #err(#NotCreator);
        };
        if(isNFTOver){
            return #err(#AlreadyOver);
        };
        if(changeTotal < request.minDrawNum){
            return #err(#NotAttachMinNum);
        };
        
        let success = await FactoryCanisterActor.setNftOwner(request.createUser);
        if(success){
            isNFTOver := true;
            lastUpdate := Time.now();
        };
        return #ok(success);
    };

    public shared(msg) func wallet_receive() : async Nat {
        let available = Cycles.available();
        let accepted = Cycles.accept(available);
        return accepted;
    };

    public query func getAllPixel() : async [(Position, Color)] {
        Iter.toArray(positionMap.entries())
    };

    public query func getWorth() : async Nat {
        totalWorth
    };

    public query func getCycles() : async Nat {
        Cycles.balance()
    };

    public query func getCreator() : async Principal {
        return request.createUser;
    };

    public query func isOver() : async Bool {
        isNFTOver
    };

    public query func getNftDesInfo(): async AloneNFTDesInfo {
        return _nftDesInfo();
    };

    private func _checkPosition(drawPosReqArray: [DrawPosRequest]): Bool {
        if(drawPosReqArray.size() > request.dimension * request.dimension){
            return false;
        };
        for(i in Iter.fromArray(drawPosReqArray)) {
            if(i.pos.x >= request.dimension or i.pos.y >= request.dimension){
                return false;
            };
        };
        return true;
    };

    private func _nftDesInfo(): AloneNFTDesInfo {
        let nftDesInfo = {
            canisterId = Principal.fromActor(this);
            createBy = request.createUser;
            name = request.name;
            desc = request.desc;
            basePrice = request.basePrice;
            isNFTOver = isNFTOver;
            totalWorth = totalWorth;
            tokenIndex = request.tokenIndex;
            backGround = request.backGround;
        };
        return nftDesInfo;
    };
}