module dev::verifier {
    use sui::tx_context::{Self, TxContext};
    use std::vector::append;
    use std::debug;
    use sui::groth16::{Curve, public_proof_inputs_from_bytes, prepare_verifying_key, 
    proof_points_from_bytes, verify_groth16_proof,  bn254};
    use sui::hex;
    use sui::url::{Self, Url};
    use std::string::{Self, String};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::object::{Self, ID, UID};
    use sui::address::{Self};
    //  public entry fun verify(proof: vector<u8>, public_1: vector<u8>, public_2: vector<u8>) {
    //     let proof_serialized = hex::decode(proof);
    //     let vk_serialized: vector<u8> = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19fa699e9b4686fe2e83e951ed08534d6ab5d093d542ee8fdd5e75100b3814f90c87d3f290481b05e1c7c8fc78dba5fb07466a907b7dfcc6002f77a0b49b9635ac0300000000000000b4562156b4f417c86474d80d460c8e373ced90ba3348154ff962ed73b56533291181cf9baaa5ae17c7a2a51a3799c4759154f0b4b27e7f766a360d28f628190daf527193c5e10913c6eb3f7b189b29ad878e0e097cf4ce2cceaec37a6f6e8c01";
    //     let curve: Curve = bn254();
    //     let public_inputs_serialized: vector<u8> = x"";
    //     append(&mut public_inputs_serialized, hex::decode(public_1));
    //     append(&mut public_inputs_serialized, hex::decode(public_2));
    //     //let proof_serialized: vector<u8> = x"887cca600d0c168ad9a4db59ac8aaeb1519bc821a0af0b5df7e459eb82660c152d1bbc390bf3b03155a8530ede05265d8c8574aece938c9d54f6950993891f7808d694c4352ef93dd1bb59e272a383e4a07c4e60a5d847f6b395dc24a00b59c5173b7a96843a2c5d1516b0ba68c96829f1a02e005dcb4d41406088a8b5d4deac527ff89db2ddc497414bdb35c229a7c786b7678ce2d5e23de57634f84567cb55b651cb5ee4910473965e2fd60755d6c89314add6024d59ea737e5bc769f9c3a8";
        

    
    //     let pvk = prepare_verifying_key(&curve, &vk_serialized);
        
    //     let public_inputs =  public_proof_inputs_from_bytes(public_inputs_serialized);
    //     let proof_points =  proof_points_from_bytes(proof_serialized);

    //     let verification_result: bool = verify_groth16_proof(&curve, &pvk, &public_inputs, &proof_points);
        
    //     //let a: u64 = 64;
    //     assert!(verification_result, 1337);
    // }

    //Shared object Map
    //Quest_id - would be kP_x, kP_y
    struct ProfessorNFT has key, store{
        id: UID,
        name: String,
        description: String,
        url: Url,
    }

    struct Answer has store{
        student_a_hash: vector<u8>, 
        student_aH_x: vector<u8>,   
        student_aH_y: vector<u8>,   
        timestamp_answered: vector<u8>, //Deal with it later
        akP_x: vector<u8>,          
        akP_y: vector<u8>,
    }

    struct Quest has key, store{
        id: UID,
        question: String,
        professor_address: address,
        professor_k_hash: vector<u8>,
        professor_kP_x: vector<u8>,
        professor_kP_y: vector<u8>,
        answers: Table<address, Answer>,
    }

    const EInvalidCommitment: u64 = 0;
    const EInvalidUnlock: u64 = 1;
    const EAnotherProfessor: u64 = 2;
    const EStudentNoAnswer: u64 = 3;
    const EProfessorBadMultiplication: u64 = 4;
    const EStudentBadMultiplication: u64 = 5;

    //Deal with timestamps later, when all proofs are working
    //And js client for student, and for professor works right

    public entry fun professor_create_quest(question: vector<u8>, proof:vector<u8>, professor_k_hash: vector<u8>,
        professor_kP_x: vector<u8>, professor_kP_y: vector<u8>, ctx: &mut TxContext)
    {
        let professor_address = tx_context::sender(ctx);

        //Immediately asserts that professot commitment is valid
        //(He used this hashed k to multiply by private input P and got public kP_x, kP_y)
        let is_valid : bool = commit(proof, professor_k_hash, professor_kP_x, professor_kP_y, address::to_bytes(professor_address));
        assert!(is_valid, EInvalidCommitment);

        //Only then creates a shared object - quest
        //Writes question text, k_hash, kP_x, kP_y
        //Auto write professor address
        let quest = Quest {
            id: object::new(ctx),
            question: string::utf8(question),
            professor_address,
            professor_k_hash,
            professor_kP_x,
            professor_kP_y,
            answers: table::new(ctx),
        };
        transfer::public_share_object(quest)   
    }

    public entry fun student_answer_question(shared_quest: Quest, ctx: &TxContext)
    {
        //Take 1 SUI for the mint anyway
        //Send it to professor address, retrieved for Quest object

        //Check that I did not answer already i.e Answers map does not have caller address key
        //Verify commitment, indeed multiplied preimage of hash by some secret point to get aH_x, aH_y
        //Write this commitment to answer
        //Verify that public professors kP_x, kP_y was indeed multiplied by some secret a, matching student's public commitment hash_a
        //Write this multiplication result to answer
        //Add me to the answer Map
        //TODO: Add timestamp here later

        //(Insight)
        //Can be easily limited to one time per address
        //Or completely unique one-time questions
    }

    public entry fun professor_score_answer(shared_quest: Quest, student: address, 
    proof:vector<u8>, professor_out_kaH_x: vector<u8>, professor_out_kaH_y: vector<u8>, ctx: &mut TxContext)
    {
        let _professor_address = tx_context::sender(ctx);
        let Quest {id, question, professor_address, professor_k_hash,
            professor_kP_x, professor_kP_y, answers} = shared_quest;

        //Assert that this question belongs to this professor
        assert!(_professor_address == professor_address, EAnotherProfessor);

        //Assert that this student answered indeed
        assert!(table::contains(&answers, student), EStudentNoAnswer);

        //Extract his answer
        let student_answer = table::borrow(&answers, student);

        let student_aH_x = student_answer.student_aH_x;
        let student_aH_y = student_answer.student_aH_y;
        
        //Do verified multiplication of student aH by k
        let multiplied = unlock(proof, professor_out_kaH_x, professor_out_kaH_y, 
        address::to_bytes(professor_address), professor_k_hash, student_aH_x, student_aH_y);

        //Assert it was verified groth16 proven
        assert!(multiplied, EProfessorBadMultiplication);

        //If verified professor_final point matches student_final_point
        let right_answer: bool = (professor_out_kaH_x == student_answer.akP_x) && (professor_out_kaH_y == student_answer.akP_y);
        if(right_answer){
            //Mint NFT to the student

        } else{
            //Otherwise just do nothing
        }
        
        //Pop the answer from answers table anyway
        table::
    }

    public entry fun student_get_timeout_reward(shared_quest: Quest, collateral : Collateral, ctx: &TxContext)
    {
        //Lookup by caller address answer in shared_quest
        //Make sure there is one

        //Retrieve its timestamp: Do later when everything else is done
        //Use clock to get current: Do later when everything else is done
        //If professor (oracle) did not check the answer in 2 minutes

        //Pop answer 
        //Reward the caller with NFT

        //Do it last
        //But first just implement free mint here for any answer and Popping of answer
        //Improve it by allowing it only after timestamp + 2 minutes
    }

    fun verify(proof: vector<u8>, vk_serialized: vector<u8>, public_inputs_serialized: vector<u8>): bool {
        let proof_serialized = hex::decode(proof);
        let curve: Curve = bn254();
        let pvk = prepare_verifying_key(&curve, &vk_serialized);
        let public_inputs =  public_proof_inputs_from_bytes(public_inputs_serialized);
        let proof_points =  proof_points_from_bytes(proof_serialized);
        verify_groth16_proof(&curve, &pvk, &public_inputs, &proof_points)
    }

    fun commit(proof: vector<u8>, public_out_hash_a: vector<u8>, public_out_aP_x: vector<u8>, 
    public_out_aP_y: vector<u8>, public_in_address: vector<u8>): bool {
        let vk_serialized: vector<u8> = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19fa699e9b4686fe2e83e951ed08534d6ab5d093d542ee8fdd5e75100b3814f90c87d3f290481b05e1c7c8fc78dba5fb07466a907b7dfcc6002f77a0b49b9635ac0300000000000000b4562156b4f417c86474d80d460c8e373ced90ba3348154ff962ed73b56533291181cf9baaa5ae17c7a2a51a3799c4759154f0b4b27e7f766a360d28f628190daf527193c5e10913c6eb3f7b189b29ad878e0e097cf4ce2cceaec37a6f6e8c01";
        let public_inputs_serialized: vector<u8> = x"";
        append(&mut public_inputs_serialized, hex::decode(public_out_hash_a));
        append(&mut public_inputs_serialized, hex::decode(public_out_aP_x));
        append(&mut public_inputs_serialized, hex::decode(public_out_aP_y));
        append(&mut public_inputs_serialized, hex::decode(public_in_address));

        let verification_result: bool = verify(proof, vk_serialized, public_inputs_serialized);
        verification_result
    }

    fun unlock(proof: vector<u8>, public_out_kaH_x: vector<u8>, public_out_kaH_y: vector<u8>, 
    public_in_address: vector<u8>, public_in_hash_k: vector<u8>, public_in_aH_x: vector<u8>, public_in_aH_y: vector<u8>, ): bool {
        let vk_serialized: vector<u8> = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19fa699e9b4686fe2e83e951ed08534d6ab5d093d542ee8fdd5e75100b3814f90c87d3f290481b05e1c7c8fc78dba5fb07466a907b7dfcc6002f77a0b49b9635ac0300000000000000b4562156b4f417c86474d80d460c8e373ced90ba3348154ff962ed73b56533291181cf9baaa5ae17c7a2a51a3799c4759154f0b4b27e7f766a360d28f628190daf527193c5e10913c6eb3f7b189b29ad878e0e097cf4ce2cceaec37a6f6e8c01";
        let public_inputs_serialized: vector<u8> = x"";
        append(&mut public_inputs_serialized, hex::decode(public_out_kaH_x));
        append(&mut public_inputs_serialized, hex::decode(public_out_kaH_y));
        append(&mut public_inputs_serialized, hex::decode(public_in_address));
        append(&mut public_inputs_serialized, hex::decode(public_in_hash_k));
        append(&mut public_inputs_serialized, hex::decode(public_in_aH_x));
        append(&mut public_inputs_serialized, hex::decode(public_in_aH_y));
    
        let verification_result: bool = verify(proof, vk_serialized, public_inputs_serialized);
        verification_result
    }

    //fun init(_ctx: &mut TxContext) {
        // transfer::transfer(CreatorCapability {
        //     id: object::new(ctx),
        // }, tx_context::sender(ctx))
        // let proof = b"a27c5205f9dfb4829a0c953d179dc171c23f5bb22ab4c866f0c090017e1ba60ab7a0f44108483acde4a05b294afafa2e2a751a0e4c6c8dc2e448161f5b35e02beaf88f2e9a8c9c5231a40083815dd30d4ad8db5a4552c3e40a67446625e1d008d4dc78a664286ca26be6ab055f1879b36f6d33f94d30581806439cf99ed9d593";
        // let public_1 = b"8101000000000000000000000000000000000000000000000000000000000000";
        // let public_2 = b"0500000000000000000000000000000000000000000000000000000000000000";
        // verify(proof, public_1, public_2);
    }




//     #[test]
//     public fun test_verify(){
//         let proof = b"a27c5205f9dfb4829a0c953d179dc171c23f5bb22ab4c866f0c090017e1ba60ab7a0f44108483acde4a05b294afafa2e2a751a0e4c6c8dc2e448161f5b35e02beaf88f2e9a8c9c5231a40083815dd30d4ad8db5a4552c3e40a67446625e1d008d4dc78a664286ca26be6ab055f1879b36f6d33f94d30581806439cf99ed9d593";
//         let public_1 = b"8101000000000000000000000000000000000000000000000000000000000000";
//         let public_2 = b"0500000000000000000000000000000000000000000000000000000000000000";
//         verify(proof, public_1, public_2);
//         //assert!(64==verify(), 1);
//         let n = 64u64;
//         debug::print(&n);
//     }
// }