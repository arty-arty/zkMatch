# 👥zkMatch 
is a two-party system to prove encrypted information match. It is a building block for verified gaming.

Two millionaires want to see if they have equal wealth without disclosing how rich they are. This is Socialist-Millionaire problem.
Here is my solution using NIZK proofs and eliptic curves. I implement it inside of a smart contract.

Surprisingly, once on a blockchain, this has a multidue applications: homework assignment verification, thinking biger, a way to port any puzzle game to blockchain, and even a web3 CAPTCHA to protect against the dark side of AI - 🦾.

# Updated section
[Crucial code changes](https://github.com/arty-arty/zkMatch/blob/8d58aa6057b3fdd7fdcdf226755e78925fe20505/sui-verifier/sources/dev_verifier.move#L239) to make production-ready added. The part before the end of updated section is new to save reading time. The rest of the write-up is unchanged.

## A synopsis

Here is a short synopsis of the algorithm, just to remind:

For gaming or CAPTCHA - secrets (=answers) are small. E.g. English language words are just 10-bits average. Hash would be instantly bruteforced with a table lookup.
That's why we need the second party to hide the secret. And a smart contract mediator to zk prove match (=answer verification) queries done correctly.

I suggest to hash answers to an elliptic curve. And do Diffie-Hellman.

Let $G$ anf $G'$ be oracle and user answers. Let, $k$, $a$ be their random keys.
Then after we do a correct Diffie-Hellman proven by a circom circuit. We get final points
$kaG$ and $akG'$. If points match then contract unlocks reward. 

<!-- 
We hash oracle true answer and person answer to curve points $G'$ and $G$ respectively. We do a Diffie-Hellman key exchange. -->

<!-- In case of 
The secret 
I want to prove that I know a secret.

To interact with humans, we the inforamtion belongs to a small set of choices. Instead of 256-bit password.
But it's not .  We -->



## A Major Application
CAPTCHA. Imagine a dApp. Most likely you interact with NFTs or tokens. In web3 projects, the majority of non-developers are attracted by this. Imagine an NFT mint. Unfortunately, real people often have almost zero chance to win. 

The more popular the project the more bots. A horde of bots. They steals all available places, long before user has time to click. It [happens a lot](https://cryptoslate.com/the-saudis-hits-number-1-on-opensea-as-bots-claim-free-mint-scammers-attack-discord/). 
Sometimes botters make mistakes and it becomes apparent. Top of the iceberg.

With zkMatch either a regular CAPTCHA answer is encoded or a word puzzle. Each user has to match the answer to mint a token. No one, without passing a CAPTCHA, can trigger the smart contract. Each failed try is paid. Bruteforcing becomes costly and infeasible.

## Security consideration 1

<!-- This is not a complete and rigorous proof, yet. Though it was my rationale when I came up with this simple system.

I know this might be obvious. I wanted to write it up, -->

Let's say $k$ is oracle's key, $a$ is player's key, $G$ is the right answer. $G'$ some answer by the player.
After one interaction the player knows $M = kG$ and $M' = kG'$. Remember that the possible answer set is small. It's just a CAPTCHA - not so many combinations. Or even a multiple choice question with three choices.

What if we additionaly know that $G = xG'$ for some $x$ from a small known set. Then bruteforce $x$ until $xM' = M$. Then the malicious player would know the true answer  $G = xG'$.
<!-- So, to protect, we must not allow correlation between different encoded answers happen.  -->

That's where try-and-increment hashing saves the day. In random oracle model, $G$ and $G'$ will not be correlated in any way.
And the protocol safe from this kind of attacks. 

## Security consideration 2

Even if the encoded answer points are random. An ability to solve Decisional-Diffie Hellman problem would break the protocol.
Let's say there is a an efficiently computable billinear mapping from this group $G_1$ to some other $G_T$ called $e: G_1 \rightarrow G_T$.
Bruteforce possilbe $G'$ from a small set until $e(kG, aG) = e(G', kaG)$. To protect, I chose a Baby Jubjub group with a high embedding degree, where pairings are computationally inefficient.

When the adversary sees more tries. Breaking the system this way tranforms into finding multi-linear pairings. And there are [some additional reasons](https://crypto.stanford.edu/~dabo/papers/mlinear.pdf) why it seems difficult.  

<!-- 
## How does it help NFTs
Yeseterday, -->

## Mini-conclusion 

The alogtihm is simple and explainable. Any developer knows Diffie-Hellman key exchange.
I hope that after some rigorous security analysis, this system spreads everywhere.

Look at what happens now. For example, Frenemies was an official contest by Sui. One could get an allocation. 
In the [leaderboard a lot of names](https://github.com/MystenLabs/sui/blob/27dec39eba9adafad68a69f55701e53986790226/sui_programmability/examples/new-frenemies/sources/migrate.move#L55) are autogenerated. Like color_animal_adjective_number. Surely, a bots predictor.

When summer approaches and Sui mainnet approaches.
We need this more than ever. In all other chains as well. A summer free of bots. Forever 🌞. For the web3.

# End of updated section

# So, how does verified match help games?

There are games to tell stories. There are games to solve mysteries. But actually, games are just tasks that require one to act in a specific way - to answer some question. 

If there is only one way to solve a level - only one answer - then zkMatch works. 
Any such game old or new can, actually, be run on-chain. Which brings a host of possibilities like - guaranteed rewards, abolished cheating. It can be placing mirrors to guide the laser through the labirynth. It can be finding one concept which unites four pictures. It can be guessing which brand is on the logo. This a general solution to rule them all.

# Demo
is an application of this principle. Here it is an NFT minting game. With a difficult puzzle only human can solve to protect against bots. See the [demo source code](https://github.com/arty-arty/zkMatch/blob/ed4e3aae599be228f97c38fc7d95cc75f4114a47/my-mint/src/App.jsx#L219).
In web3 projects, the majority of non-developer users are attracted by interacting with tokens or NFTs. Unfortunately, real people often have almost zero chance to win. The more popular the project the more bots. The bots horde, steals all available places, long before the user has time to click.

We solve this problem once and for all with a simple to implement zk scheme.
A [demo is hosted here](https://cheerful-cheesecake-30269e.netlify.app/). It needs my computer running the oracle. So, there is a [YouTube demo variant](https://youtu.be/PdydslqjhMo), just in case.

# The algorithm shortly

A point on an elliptic curve denotes the right answer. Here I implemented simple [try-and-increment encoding](https://github.com/arty-arty/zkMatch/blob/master/boneh-encode/hash_to_curve.js). If a human and captcha server, using groth16, prove
that they did a Diffie-Hellman key exchange, and they arrived at the same point, then the answer is right. 

Those two circuits: the first one for initial commitment to the key, and the second for proven multiplication are
in: [commit.circom](https://github.com/arty-arty/zkMatch/blob/master/commit.circom) and [unlock.circom](https://github.com/arty-arty/zkMatch/blob/master/unlock.circom)

# When it works 

The security proof relies on DDH - Decisional Diffie-Hellman assumption. It holds for elliptic curves with high embedding degree where pairings are not efficiently computable. 

When the adversary sees more tries. Breaking the system this way tranforms into finding multi-linear pairings. And there are [some additional reasons](https://crypto.stanford.edu/~dabo/papers/mlinear.pdf) why it seems difficult.  

# Why non-trivial

The difficulty was that it involes two parties, say, student and professor. So it is a multi-party computation protocol. The professor holds a secret - the true answer. The hardest thing, this answer belongs to a very small set. Might be just three options for a multiple choice test.

So, trusting the true answer, even hashed to a smart contract is insecure. (Salting the hash is not an option.
It works, but anyway means that the salt is a secret stored by another party) 

Even a more general statement. If there is enough information to verify the answer in the smart-contract. And we want verification to be quick. And this chain does not support secret sharing. Then such smart-contract might be dry-run. The perpetrator could just simulate calling the contract and instantly guess which option from three was correct. That's why we anyway need at least second party to hold the secret safely.

# Why zkNARK

The use-case of NARK here is to prove that each party follows the multi-party computataion protocol as it's written. The groth16 prover is implemented in [the smart contract, please see it.](https://github.com/arty-arty/zkMatch/blob/master/sui-verifier/sources/dev_verifier.move) The contract acts as middleman. It de-incentivizes both sides for not providing the proof in time. And makes cheating meaningless and costly.

The cost of a try can be [tweaked here](https://github.com/arty-arty/zkMatch/blob/ed4e3aae599be228f97c38fc7d95cc75f4114a47/sui-verifier/sources/dev_verifier.move#L124). 
[Use deploy.js](https://github.com/arty-arty/zkMatch/blob/master/client-scripts/deploy.js) if you want to ship your own version.
The contract can handle as many different questions at the same time as one neeeds.

# A bit more details on the algorithm

The idea is to encode the answers by hashing to a point on the elliptic curve, and prove that both parties obeyed Diffie-Hellman exchange. 
If they could arrive at the same point it means that they started from the same point, if they could not then answers were different.

To ellaborate, P is a to-curve hash of my answer. And k is my random key. And a is professor's random key. I commit to kP and professor commited to aP'. We do proven by a circom circuit Diffie-Hellman. We get akP and akP'. Look more into [professor.js to see implementation](https://github.com/arty-arty/zkMatch/blob/master/client-scripts/professor.js) of this oracle logic.

Then if they are equal we had same answers. Seems like no information leaked under Decisional Diffie-Hellman assumption. Or some sort of a multi-linear generalization, if many past tries are available in public.

# Conclusion

I hope that this working prototype sparks more converstation about verified games. And their general - often occuring - bulding blocks.
Here the demo is a captcha system, but most of the puzzle games can be expressed in question-answer format. So, the same smart contract on Sui testnet can "supervise" such games.
So, there is no more cheating and there are always guaranteed rewards. The future of games!




