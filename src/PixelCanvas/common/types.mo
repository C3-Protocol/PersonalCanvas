import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import List "mo:base/List";
import Time "mo:base/Time";
import Hash "mo:base/Hash";

module Types = {

  public let ONE_DAY_NANOSECONDS: Nat = 86_400_000_000_000; // 24 hours
  public let CREATEALONECANISTER_FEE : Nat = 5_000_000;  //0.05 ICP
  public let CREATEMULTICANISTER_FEE : Nat = 10_000_000;  //0.1 ICP
  public let DIMENSION: Nat = 200;
  public let GROWRATIO: Nat = 130;
  public let BASCIOPERATING_PRICE: Nat = 10_000;
  public let THEMEBASCIOPERATING_PRICE: Nat = 1_000;
  public let CREATECANVAS_CYCLES: Nat = 1_000_000_000_000;  //1 T
  public let MINCYCLES_CANISTER: Nat = 1_000_000_000_000;  //1T
  public let MINDRAWNUM: Nat = 500;    //

  public type Result<T,E> = Result.Result<T,E>;
  public type TokenIndex = Nat;
  public type Color = Nat;

  public type Balance = Nat;
  
  public type AirDropStruct = {
    user: Principal;
    remainTimes: Nat;
  };

  public type DisCountStruct = {
    user: Principal;
    disCount: Nat;
  };

  public type PreMint = {
    user: Principal;
    index: Nat;
  };

  public type AirDropResponse = Result.Result<CanvasIdentity, {
    #NotInAirDropListOrAlreadyCliam;
    #AlreadyCliam;
  }>;

  public type MintZombieResponse = Result.Result<[CanvasIdentity], {
    #Unauthorized;
    #LessThanFee;
    #InsufficientBalance;
    #AllowedInsufficientBalance;
    #Other;
    #SoldOut;
    #NotOpen;
    #NotEnoughToMint;
    #NotWhiteListOrMaximum;
  }>;

  public type DrawPosRequest = {
    pos: Position;
    color: Color;
  };

  public type CanvasIdentity = {
    index: TokenIndex;
    canisterId: Principal;
  };

  public type MultiCanvasAccInfo = {
    consume: Nat;
    income: Nat;
    withDrawed: Nat;
    userBonus: Nat;
    pixelNum: Nat;
  };

  public type MultiNFTDesInfo = {
    canisterId: Principal;
    createBy: Principal;
    name: Text;
    desc: Text;
    lastUpdate: Time.Time;
    basePrice: Nat;
    growRatio: Nat;
    changeTotal: Nat;
    bonusPixelThreshold: Nat;
    totalWorth: Nat;
    isNFTOver: Bool;
    bonus: Nat;
    bonusWinner: ?Principal;
    tokenIndex: Nat;
    paintersNum: Nat;
  };

  public type AloneNFTDesInfo = {
    canisterId: Principal;
    createBy: Principal;
    name: Text;
    desc: Text;
    basePrice: Nat;
    totalWorth: Nat;
    isNFTOver: Bool;
    tokenIndex: Nat;
    backGround: Nat;
  };

  public type ThemeNFTDesInfo = {
    canisterId: Principal;
    createBy: Principal;
    name: Text;
    desc: Text;
    finshTime: Time.Time;
    basePrice: Nat;
    changeTotal: Nat;
    totalWorth: Nat;
    isNFTOver: Bool;
    tokenIndex: Nat;
    paintersNum: Nat;
  };

  public type CreateCanvasResponse = Result.Result<CanvasIdentity, {
    #Unauthorized;
    #LessThanFee;
    #InsufficientBalance;
    #AllowedInsufficientBalance;
    #InsufficientCycles;
    #ExceedMaxNum;
    #NotBeInvited;
    #Other;
  }>;

  public type DrawResponse = Result.Result<Bool, {
    #Unauthorized;
    #LessThanFee;
    #InsufficientBalance;
    #AllowedInsufficientBalance;
    #NFTDrawOver;
    #PositionError;
    #NotAttachGapTime;
    #Other;
    #NotBeInvite;
    #NotOpen;
  }>;

  public type DrawOverResponse = Result.Result<Bool, {
    #NotCreator;
    #AlreadyOver;
    #NotAttachMinNum;
  }>;

  public type LotteryResponse = Result.Result<Principal, {
    #NotThreshold;
    #SetOwnerFail;
    #BonusDropFail;
    #Other;
  }>;

  public type TransferResponse = Result.Result<TokenIndex, {
    #NotOwnerOrNotApprove;
    #NotAllowTransferToSelf;
    #ListOnMarketPlace;
    #Other;
  }>;

  public type BuyResponse = Result.Result<TokenIndex, {
    #Unauthorized;
    #LessThanFee;
    #InsufficientBalance;
    #AllowedInsufficientBalance;
    #NotFoundIndex;
    #NotAllowBuySelf;
    #AlreadyTransferToOther;
    #Other;
  }>;

  public type WithDrawResponse = Result.Result<Nat, {
    #Unauthorized;
    #LessThanFee;
    #InsufficientBalance;
    #AllowedInsufficientBalance;
    #BonusNotActive;
    #Other;
  }>;

  public type Asset = {
    invest: Nat;
    income: Nat;
    withdraw: Nat;
  };

  public type Pixel = {
    curOwner: Principal;
    prevOwner: Principal;
    curPrice: Nat;
    color: Color;
  };

  public type ListRequest = {
    tokenIndex : TokenIndex;
    price : Nat;
  };

  public type Listings = { 
    tokenIndex : TokenIndex; 
    seller : Principal; 
    price : Nat;
    time : Time.Time;
  };

  public type GetListingsRes = { 
    listings : Listings;
    rarityScore : Float;
    CE : Nat;
  };

  public type SoldListings = {
    lastPrice : Nat;
    time : Time.Time;
    account : Nat;
  };

  public type GetSoldListingsRes = { 
    listings : SoldListings;
    rarityScore : Float;
    CE : Nat;
  };

  public type Operation = {
    #Mint;
    #List;
    #UpdateList;
    #CancelList;
    #Sale;
    #Transfer;
    #Bid;
  };

  public type OpRecord = {
    op: Operation;
    price: ?Nat;
    from: ?Principal;
    to: ?Principal;
    timestamp: Time.Time;
  };

  public type AncestorMintRecord = {
    index: Nat;
    record: OpRecord;
  };

  public type DrawRecord = {
    painter: Principal;
    index: Nat;
    num: Nat;
    consume: Nat;
    memo: ?Text;
    updateTime: Time.Time;
  };

  public type ListResponse = Result.Result<TokenIndex, {
    #NotOwner;
    #NotFoundIndex;
    #AlreadyList;
    #NotApprove;
    #NotNFT;
    #SamePrice;
    #Other;
  }>;

  public type Position = {
    x: Nat;
    y: Nat;
  };

  public type PixelInfo = {
    color: Color;
    price: Nat;
  };

  public type MintMultiNFTRequest = {
    name: Text;
    desc: Text;
    createFee: Nat;
    owner: Principal;
    createUser: Principal;
    wicpCanisterId: Principal;
    tokenIndex: Nat;
    dimension: Nat;
    basePrice: Nat;
    growRatio: Nat;
    deadline: Nat;
  };

  public type MintAloneNFTRequest = {
    name: Text;
    desc: Text;
    createFee: Nat;
    owner: Principal;
    createUser: Principal;
    feeTo: Principal;
    wicpCanisterId: Principal;
    tokenIndex: Nat;
    dimension: Nat;
    basePrice: Nat;
    minDrawNum: Nat;
    backGround: Nat;
  };

  public type BonusParamPercent = {
    feedBackPercent: Nat;                           
    bonusWinnerPercent: Nat;                       
    bonusCreatorPercent: Nat;                  
    bonusAllUserPercent: Nat;
  };

  public type MintNFTRequest = {
    name: Text;
    desc: Text;
  };

  public type MintAloneRequest = {
    name: Text;
    desc: Text;
    backGround: Nat;
  };

  public type MintThemeRequest = {
    name: Text;
    desc: Text;
    deadline: Nat;
  };

  public type MultiStorageActor = actor {
    setParticipate : shared (user: Principal, info: CanvasIdentity) -> async ();
    setFavorite : shared (user: Principal, info: CanvasIdentity) -> async ();
    cancelFavorite : shared (user: Principal, info: CanvasIdentity) -> async ();
    addRecord : shared (index: TokenIndex, op: Operation, from: ?Principal, to: ?Principal, 
        price: ?Nat, timestamp: Time.Time) -> async ();
    addBuyRecord : shared (index: TokenIndex, from: ?Principal, to: ?Principal, 
        price: ?Nat, timestamp: Time.Time) -> async ();
  };

  public type AloneStorageActor = actor {
    setFavorite : shared (user: Principal, info: CanvasIdentity) -> async ();
    cancelFavorite : shared (user: Principal, info: CanvasIdentity) -> async ();
    addRecord : shared (index: TokenIndex, op: Operation, from: ?Principal, to: ?Principal, 
        price: ?Nat, timestamp: Time.Time) -> async ();
    addBuyRecord : shared (index: TokenIndex, from: ?Principal, to: ?Principal, 
        price: ?Nat, timestamp: Time.Time) -> async ();
  };

  public type ZombieStorageActor = actor {
    setFavorite : shared (user: Principal, info: CanvasIdentity) -> async ();
    cancelFavorite : shared (user: Principal, info: CanvasIdentity) -> async ();
    addRecord : shared (index: TokenIndex, op: Operation, from: ?Principal, to: ?Principal, 
        price: ?Nat, timestamp: Time.Time) -> async ();
    addBuyRecord : shared (index: TokenIndex, from: ?Principal, to: ?Principal, 
        price: ?Nat, timestamp: Time.Time) -> async ();
    addRecords : shared (records: [AncestorMintRecord]) -> async ();
  };

  public func equal(a: Position, b: Position) : Bool {
    (a.x == b.x) and (a.y == b.y)
  };
  
  public func hash(a: Position) : Hash.Hash {
    let text = Text.concat(Nat.toText(a.x), Nat.toText(a.y));
    Text.hash(text)
  };

  public func compare(x : (TokenIndex, Principal), y : (TokenIndex, Principal)) : { #less; #equal; #greater } {
    if (x.0 < y.0) { #less }
    else if (x.0 == y.0) { #equal }
    else { #greater }
  };

  public func compareNat(x : (Principal, Nat), y : (Principal, Nat)) : { #less; #equal; #greater } {
    if (x.1 > y.1) { #less }
    else if (x.1 == y.1) { #equal }
    else { #greater }
  };

  public module TokenIndex = {
    public func equal(x : TokenIndex, y : TokenIndex) : Bool {
      x == y
    };
    public func hash(x : TokenIndex) : Hash.Hash {
      Text.hash(Nat.toText(x))
    };
  };

}

