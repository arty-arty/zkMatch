pragma circom 2.1.4;

include "circomlib/poseidon.circom";
include "circomlib/babyjub.circom";
include "circomlib/escalarmulany.circom";

// include "https://github.com/0xPARC/circom-secp256k1/blob/master/circuits/bigint.circom";

template MyMul() {
    signal input coeff, x, y;
    signal output xout, yout;

     // Convert the a key to bits
    component privKeyBits = Num2Bits(253);
    privKeyBits.in <== coeff;
    
    // a ** P(x, y)
    component c1x = EscalarMulAny(253);
    for (var i = 0; i < 253; i ++) {
        c1x.e[i] <== privKeyBits.out[i];
    }
    c1x.p[0] <== x;
    c1x.p[1] <== y;

    xout <== c1x.out[0];
    yout <== c1x.out[1];
}

template Example () {
    signal input address, k, P_x, P_y, hash_k, kP_x, kP_y, aH_x, aH_y;
    signal output kaH_x, kaH_y;
    
    address * 0 === 0;
    
    // Check all points are on curve
    component check_P = BabyCheck();
    check_P.x <== P_x;
    check_P.y <== P_y;

    component check_kP = BabyCheck();
    check_kP.x <== kP_x;
    check_kP.y <== kP_y;

    component check_aH = BabyCheck();
    check_aH.x <== aH_x;
    check_aH.y <== aH_y;
     
    // Check the hash_k
    component hash_check = Poseidon(1);
    hash_check.inputs[0] <== k;
    hash_check.out === hash_k;

    // Check kP is actually k*P
    component mml_k_P = MyMul();
    mml_k_P.coeff <== k;
    mml_k_P.x <== P_x;
    mml_k_P.y <== P_y;

    mml_k_P.xout === kP_x;
    mml_k_P.yout === kP_y;

    // Calculate output kaH_x, kaH_y
    component mml_k_aH = MyMul();
    mml_k_aH.coeff <== k;
    mml_k_aH.x <== aH_x;
    mml_k_aH.y <== aH_y;

    mml_k_aH.xout ==> kaH_x;
    mml_k_aH.yout ==> kaH_y;
}

component main { public [ address, hash_k, kP_x, kP_y, aH_x, aH_y ] } = Example();

/* INPUT = {
    "address": "1337",

    "k"  : "21888242871839275222246405745257275088614511777268538073601725287587578984328",
    "P_x" : "995203441582195749578291179787384436505546430278305826713579947235728471134",
    "P_y" : "5472060717959818805561601436314318772137091100104008585924551046643952123905",

    "hash_k": "21356175538921533842148623498297006446606795514370596108568498988367850556518",
    "kP_x" :  "17268995355595093346924002144232936458990546388123140353144774856076376646691",
    "kP_y" :  "5169358460039288903446151615210977832767877682757582369441968919468995638557",

    "aH_x":   "13588561575246442548455582745542485234097730117018791270902675311173615549288",
    "aH_y":   "308111687958528632616916277249447030871128397260475082311634915123542597200"
} */
