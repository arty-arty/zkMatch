const snarkjs = require("snarkjs");
const fs = require("fs");
const { string_to_curve } = require("../boneh-encode/hash_to_curve");
const { vkey_serialize, vkey_prepared_serialize, proof_serialize, public_input_serialize } = require("../ark-serializer/pkg_node");
require('dotenv').config();
const { localnetConnection, testnetConnection, TransactionBlock, Ed25519Keypair, JsonRpcProvider, RawSigner, mnemonicToSeed, Ed25519PublicKey, hasPublicTransfer } = require('@mysten/sui.js');
const { BCS, getSuiMoveConfig } = require("@mysten/bcs");
const { exit } = require("process");

const bcs = new BCS(getSuiMoveConfig());

//Please write verifier_pkg id in package.id text file. Notice it is automatically done when deployed with deploy.js
const verifier_pkg = fs.readFileSync('package.id', 'utf8').trim();
console.log(verifier_pkg);

//!!Please notice that it must be kept secret!!
//In production this oracle code runs on a secure server
//Which only professor - key holder - can access
//Key is a random number less than cyclic subgroup order 2736030358979909402780800718157159386076813972158567259200215660948447373041
const professor_key = "21";
const right_answer = "peace"
const { xx: P_x, yy: P_y } = string_to_curve(right_answer);
const mnemonic = process.env.PHRASE;
//!!End of must be kept secret section!!

function arr_to_bigint(arr) {
    //let arr = new Uint8Array(buf);
    let result = BigInt(0);
    for (let i = arr.length - 1; i >= 0; i--) {
        result = result * BigInt(256) + BigInt(arr[i]);
    }
    return result;
}

function arr_from_hex(hexString) {
    const _hexString = hexString.replace("0x", "");
    console.log(_hexString);
    const hex = Uint8Array.from(Buffer.from(_hexString, 'hex'));
    console.log(hex);
    return hex;
}

function addr_to_bigint(addr, flush = true) {
    const interm = arr_from_hex(addr);
    //Zeroize the last - most significant byte of address to prevent the number being bigger than base Field modulo
    if (flush) interm[31] = 0;
    return arr_to_bigint(interm);
}

const utf8_hex_to_int = (by) => {
    const st = Buffer.from(by).toString('utf8');
    //console.log({ st })
    const arr = Uint8Array.from(Buffer.from(st, 'hex'));
    //console.log({ arr })
    return arr_to_bigint(arr)
}

const keypair = Ed25519Keypair.deriveKeypair(mnemonic);
const provider = new JsonRpcProvider(testnetConnection);
const signer = new RawSigner(keypair, provider);

async function prepare() {
    const addr = await signer.getAddress()

    const addr_for_proof = addr_to_bigint(addr).toString();
    console.log(addr_for_proof);

    const { proof: proof_upload_quest, publicSignals: publicSignals_upload_quest } = await snarkjs.groth16.fullProve({ address: addr_for_proof, a: professor_key, P_x, P_y }, "compiled_circuits/commit_main.wasm", "compiled_circuits/commit_main.groth16.zkey");
    console.log({ P_x, P_y, proof_upload_quest: JSON.stringify(proof_upload_quest), publicSignals_upload_quest })

    return { addr, addr_for_proof, proof_upload_quest, publicSignals_upload_quest }
}


async function upload_quest() {
    const { addr, addr_for_proof, proof_upload_quest, publicSignals_upload_quest } = await prepare()
    //Now serialzie with my ark-serialize the proof
    const proof_serialized = proof_serialize(JSON.stringify(proof_upload_quest));
    console.log({ proof_serialized })

    //Now serialzie with my ark-serialize the public inputs    
    const signals = publicSignals_upload_quest.map((input) => public_input_serialize(input))
    console.log({ signals })

    const [professor_k_hash, kP_x, kP_y, _] = signals
    console.log(professor_k_hash, kP_x, kP_y);

    //Check proof
    const vKey = JSON.parse(fs.readFileSync("compiled_circuits/commit_main.groth16.vkey.json"));

    const res = await snarkjs.groth16.verify(vKey, publicSignals_upload_quest, proof_upload_quest);

    if (res === true) {
        console.log("Verification OK");
    } else {
        console.log("Invalid proof");
    }

    //Send the transaction to the verifier implemented in ../sui-verifier/sources/dev_verifier.moive on-chain smart contract
    const tx = new TransactionBlock();

    //Smart contract verifier::professor_create_quest method signature
    //question: vector<u8>, proof:vector<u8>, professor_k_hash: vector<u8>,
    //professor_kP_x: vector<u8>, professor_kP_y: vector<u8>
    tx.moveCall({
        target: verifier_pkg + '::verifier::professor_create_quest',
        typeArguments: [],
        arguments: [
            tx.pure("What do you get when you add the right word to the end of this puzzle? : "),
            tx.pure(proof_serialized),
            tx.pure(professor_k_hash),
            tx.pure(kP_x),
            tx.pure(kP_y),
        ],
        gasBudget: 10000
    }
    )
    const result = await signer.signAndExecuteTransactionBlock({ transactionBlock: tx });
    console.log({ result });

    await new Promise(r => setTimeout(r, 10000));

    //const result = { digest: "3DCpgh2iRkRgbYG8L6mFChez73YWpbKdFh7uMBK6wPXQ" };
    //Lookup this transaction block by digest
    const effects = await provider.getTransactionBlock({
        digest: result.digest,
        // only fetch the effects field
        options: { showEffects: true },
    });

    console.log({ result }, effects, effects.effects.created[0].reference.objectId);
    const created = effects.effects.created.filter(effect => "Shared" in effect.owner)
    console.log(created)
    const quest_id = created[0].reference.objectId;

    fs.writeFile('quest.id', quest_id, (err) => {
        if (err) throw err;
        console.log('Quest ID saved to file!');
    });

    //And fill table_id
}

//const uploaded_quest_id = "0xde0b0a7c3ce34daaeb9209d1466672312cf8afc4f28b65056b8ea7991a5c3cf5";

// async function run() {
//     const professor_addr_bytes = bcs.ser("address", verifier_pkg).toBytes()
//     //const hex = Uint8Array.from(Buffer.from("ba83bbc76bb22ad7f1e62a6e3f2d129df729f4489af8f75b06fec1f91b38acfc", 'hex'));
//     //console.log(professor_addr_bytes, hex)

//     const { proof, publicSignals } = await snarkjs.groth16.fullProve({ address: 10, a: 21, P_x: "995203441582195749578291179787384436505546430278305826713579947235728471134", P_y: "5472060717959818805561601436314318772137091100104008585924551046643952123905" }, "compiled_circuits/commit_main.wasm", "compiled_circuits/commit_main.groth16.zkey");

//     console.log("Proof: ");
//     console.log(JSON.stringify(proof, null, 1));

// }

//Write a new function where 
//First I fetch the answers from my uploaded_quest_id
//If it is not there I fetch the answers table

//Now loop through every answer I have
//And apply another function I wrote
//Called 

async function process_answer(quest_id, student_address, student_aH_x, student_aH_y) {
    const { addr, addr_for_proof, proof_upload_quest, publicSignals_upload_quest } = await prepare();
    console.log({ student_address, student_aH_x, student_aH_y });

    const professor_k_hash_int = publicSignals_upload_quest[0];

    //Convert address, student_aH_x, student_aH_y to decimal numbers represented as a string
    //const student_address_int = addr_to_bigint(student_address).toString()
    const student_aH_x_int = utf8_hex_to_int(student_aH_x).toString()
    const student_aH_y_int = utf8_hex_to_int(student_aH_y).toString()

    //BEGIN: Generate unlock proof of professor multiplied student point with her same key 
    const { proof: proof_unlock, publicSignals: publicSignals_unlock } = await snarkjs.groth16.fullProve({ address: addr_for_proof, k: professor_key, hash_k: professor_k_hash_int, aH_x: student_aH_x_int, aH_y: student_aH_y_int }, "compiled_circuits/unlock_main.wasm", "compiled_circuits/unlock_main.groth16.zkey");
    console.log({ proof: JSON.stringify(proof_unlock), publicSignals_unlock })

    const proof_unlock_serialized = proof_serialize(JSON.stringify(proof_unlock));
    console.log({ proof_unlock_serialized })

    //Now serialzie with my ark-serialize the public inputs    
    const signals_unlock = publicSignals_unlock.map((input) => public_input_serialize(input))
    console.log({ signals_unlock })

    const [kaH_x, kaH_y, , ,] = signals_unlock
    console.log({ kaH_x, kaH_y });
    //END: Generate unlock proof of professor multiplied student point with her same key//

    //And send it to the contract for verification
    const tx = new TransactionBlock();

    //Smart contract method signature of professor_score_answer(shared_quest: &mut Quest, student: address, 
    //proof:vector<u8>, professor_out_kaH_x: vector<u8>, professor_out_kaH_y: vector<u8>, ctx: &mut TxContext)
    tx.moveCall({
        target: verifier_pkg + '::verifier::professor_score_answer',
        typeArguments: [],
        arguments: [
            tx.pure(quest_id),
            tx.pure(student_address),

            tx.pure(proof_unlock_serialized),
            tx.pure(kaH_x),
            tx.pure(kaH_y),
        ],
        gasBudget: 10000
    }
    )
    const result = await signer.signAndExecuteTransactionBlock({ transactionBlock: tx }).catch((err) => console.log("We had a transaction error", err));
    console.log({ result });
}

async function fetch_answers(quest_id) {
    // const { data: { content: quest_object } } = await provider.getObject({
    //     id: quest_id,
    //     // fetch the object content field
    //     options: { showContent: true },
    // });
    // const { answers } = quest_object.fields;
    // console.log({ quest_object, answers }, answers)



    // const devnetNftFilter = { MoveModule: { package: verifier_pkg, module: 'verifier' } };

    // const devNftSub = await provider.subscribeEvent({
    //     filter: devnetNftFilter,
    //     onMessage(event) {
    //         console.log({ event });
    //         process_answer(event.parsedJson.student_address, event.parsedJson.student_aH_x, event.parsedJson.student_aH_y);
    //         // handle subscription notification message here
    //     },
    // });
    // console.log("You dont");

    // let nextCursor = null;
    // let hasNextPage = false;
    // do {
    //     const res = await provider.queryEvents({
    //         query: devnetNftFilter, limit: 1, cursor: ,
    //     });
    //     console.log({ res });
    //     let { hasNextPage, nextCursor } = res;
    // }
    // while (hasNextPage)

    console.log("Do you see me")
    process.stdin.resume();
}

async function table_field_to_answer(quest_id, table_field) {
    const { data: { content: { fields: value } } } = await provider.getObject({
        id: table_field,
        // fetch the object content field
        options: { showContent: true },
    });
    console.log(value.value.fields)

    const { student_address, student_aH_x, student_aH_y } = value.value.fields;
    await process_answer(quest_id, student_address, student_aH_x, student_aH_y);
}

// let quest_id = ""
async function run() {
    let quest_id = null;

    try {
        quest_id = fs.readFileSync('quest.id', 'utf8').trim();
    }
    catch { upload_quest() }


    if (quest_id) {

        while (1 == 1) {
            try {
                const objects = await provider.getDynamicFields({
                    parentId: quest_id,
                    // fetch the object content field
                    //options: { showContent: true },
                });
                const table_id = objects.data[0].objectId;

                //Do below every 10 seconds
                const table_fields = await provider.getDynamicFields({
                    parentId: table_id,
                    // fetch the object content field
                    //options: { showContent: true },
                });
                console.log(table_id, table_fields);

                //Now in parallel launch process all the answers found not just [0]
                table_fields.data.map(async (obj) => await table_field_to_answer(quest_id, obj.objectId));
                await new Promise(r => setTimeout(r, 10000));
                console.log("Looped another time")
            }
            catch (err) {
                console.log("For some reason failed to process answers", err)
            }
            //fetch_answers(quest_id)
        }
    }

}

run()
//fetch_answers()
//console.log(quest_id)
//upload_quest()
//If no file then upload_quest
//If there is file then fetch quest id
//And go to infinite wait for subscription mode


//publish()

//fetch_answers(uploaded_quest_id);
//console.log("subscribed")
//while (1 == 1) { }

async function process_answers() {

}

async function professor_loop() {

}



//upload_quest()

// run().then(() => {
//     process.exit(0);
// });



// Interaction with Sui network
//
// import { localnetConnection, Transaction, Ed25519Keypair, JsonRpcProvider, RawSigner, mnemonicToSeed, Ed25519PublicKey, hasPublicTransfer } from '@mysten/sui.js';

// 
// const keypair = Ed25519Keypair.deriveKeypair(mnemonic);

// const provider = new JsonRpcProvider(localnetConnection);
// const signer = new RawSigner(keypair, provider);

// const addr = await signer.getAddress()
// console.log(addr);

// function fromh(hexString) {
//     const hex = Uint8Array.from(Buffer.from(hexString, 'hex'));
//     return hex;
// }

// const proof = "a27c5205f9dfb4829a0c953d179dc171c23f5bb22ab4c866f0c090017e1ba60ab7a0f44108483acde4a05b294afafa2e2a751a0e4c6c8dc2e448161f5b35e02beaf88f2e9a8c9c5231a40083815dd30d4ad8db5a4552c3e40a67446625e1d008d4dc78a664286ca26be6ab055f1879b36f6d33f94d30581806439cf99ed9d593";
// //let proof = x"b5abd09b09edf67ba4d11505d5962eaeaa3435d0cd87ea95acbc1a25fa05876456180c568ad34330fcd2e62a06d55c0b8851f70afb3b1c98db175a939f1452551c23ba4b69fee66e5c147600759a54407882b0361db55a96db93b5c753e123e8000b2081afad61abc7c3f695900dd7507e77f96be3859e3c801b665c4bff3c5e492ef74457887cbe7be65f93d9cb61498e3c52c740b3b03ef82bf0827e93a3a60335e56b2df97070723af1d61a51a5917f47c4d315180c6a42a75340f789719c"

// const tx = new Transaction();

// tx.moveCall({
//     target: '0xb1c86d474588531316c35dc8e9f3d2535bea7294087328f53b2801cfb09b99f1::verifier::verify',
//     typeArguments: [],
//     arguments: [
//         tx.pure(proof)
//     ],
//     gasBudget: 10000
// }
// )
// const result = await signer.signAndExecuteTransaction({ transaction: tx });
// console.log({ result });


