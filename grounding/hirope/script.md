### First slide

_Comment_: greet, introduce yourself, read out the title of the article.
### Motivation

#### Inductive bias: Main idea

Recently the field of natural language modeling has developed a lot thanks to transformers. However, code modeling tasks, such as completion, generation, bug localization, refactoring and others, have **their own specifics different from NLP tasks**. One of them is a set of inductive biases that are not represented in the original Transformer architecture, which forces the model to learn them from data. So, what is an inductive bais? [pause].

_Comment_: just go through slide: ..., [pause], ... .
#### Inductive bias: Hierarchical code structure

One of such a prior knowledge about data is its hierarchical structure. Almost any project with minimally complex logic and implemented in some programming language has a hierarchical structure - it consists of folders, packages, modules, which themselves consist of files with code that can be represented as an abstract syntax tree.

In this way **one can attempt to explicitly embed this knowledge into the model architecture**.
#### Long contexts

For high-quality code modeling, the model must be able to perceive the global context of the project: how classes are related to each other, which methods are already implemented in the project, and which methods must be imported from third-party libraries, which third-party libraries are already used, and adding which ones will be an additional dependency limiting flexibility and code support, etc.

In general, this task is constrained by the **limited length of the model context** and **the quality of retrieve-systems**. The method proposed by the authors of this paper focuses on the first problem. One of its factors is poor extrapolation properties of one of the most popular methods of positional token encoding - RoPE.

Comment: RoPE is labeled in blue on the left plot, on the right plot under the name Rotary. The y-axis is perplexity, you can think of it as a cross-entropy exponent. That is, smaller values characterize a better model.

Taking into account both of these specifics of the problem, the authors of the paper propose to **explicitly introduce hierarchical information into the model at the time of positional encoding of tokens**.
### Preliminary

#### A quick overview of the Transformer architecture

The original architecture presented in Attention is All You Need 2017 consists of two parts, an encoder and a decoder. However, for language modeling, only the second one is often used, which has a causal masking of the attention matrix that prevents data leakage of tokens at the time the model is trained. This allows the model to perform a single forward pass on the entire sequence. This is actually not the only contribution of causal masking to the architecture. There is another paper proving that it also introduces positional awareness of tokens to the model. However, this effect is very weak and it is accepted in addition to use other methods to introduce positional information.

By the way, this is not required for all variations of RNNs, as this effect is already present in their architecture at a strong enough level.
#### Attention mechanism: Notations

Let's introduce the necessary notations. From the whole architecture we will need to remember the attention formula. For simplicity **we will limit ourselves to one head and the absence of a causal mask**.

[pause].

Attention mechanism in a more general case can be described as follows. Queries, keys and value vectors can be derived from the semantic embedding of the corresponding token by means of three parameterized vector functions that take as input its positional index in the input sequence in addition to the embedding itself. This is followed by the computation of attention scores using softmax and a convex combination of the value vectors.

Different methods of positional encoding can be considered as a pre-definition of $f$ functions. Let's look at a couple of classical examples and then move on to RoPE.
#### Positional encoding baselines

As mentioned earlier a decoder model does not need to receive additional information about the input to be a sequence model. NoPE, which stands for No Positional Encoding, can act as a good baseline for comparing other methods. All three of our functions from the previous slide take this form.

[pause]

The first and at one time the most popular method of positional encoding was the addition or concatenation of positional embedding with semantic embedding of the token corresponding to this position. Two variants of deriving such additions have been proposed:

1. By using sinusoidal function
2. Incorporating the embedding table into the set of model parameters and learning them during model training

**Both methods have approximately the same quality.**
Their disadvantages are as follows:

- The positional information is embedded once **at the very beginning of a token's residual stream**, which either reduces its semantic capacity in the case of addition or increases the computational cost in the case of concatenation. At the same time, deeper layers are more difficult to process and persist positional information.

- The absoluteness of positioning brings its own limitations. For example, the relation between a pair of semantic embedding $\mathbf{x}$ and its positional complement $\mathbf{p}_i$ must be learned by the model for each such pair separately. Since there are $m \cdot n$ pieces of such relations, where $m$ is the size of the vocabulary and $n - 1$ is the maximum positional index, this can cause problems already at the interpolation stage in case of insufficient representation of pairs in the training data.

- **Explicit constraint on the context length** either by the periodicity of the vector function or by the size of the positional embedding table.
### RoPE

#### RoPE: General idea

RoPE stands for Rotary Position Embedding. Let us consider what lies at its core.

We can represent a $d$-dimensional vector as a set of $d/2$ two-dimensional vectors. The position index of the token $m$ is then used to rotate each of these embedding pieces. The value of the rotation angle depends on the index of both the token itself (i.e., $m$) and the index of the chunk (the value of $\theta_j$). The rotation is performed only over query and key vectors.
#### RoPE: A 2D case

Let us consider what happens at the level of one such chunk. For now you can think that the dimensionality of our embeddings is $2$.

[pause]

_Comment_: just go through slide: ..., [pause], ... .
#### RoPE: General form

_Comment_: just go through slide.
#### RoPE: Properties

In addition to being a beautiful mathematical idea, RoPE has a number of significant properties.

_Comment_: just go through slide.
### HiRoPE
#### HiRoPE: Hierarchical format

HiRoPE includes two modifications to the original RoPE. The first is the addition of a hierarchical format.

_Comment_: just go through slide.

At the same time, **the first positional axis retains the original token indices**. The authors explain this technical solution by the fact that RoPE has large $\theta$ frequencies on the lower dimensions, which focuses the model on the dependencies of tokens close to each other. They preserve this property of the model in HiRoPE as well.
#### HiRoPE: Window mechanism

In order for HiRoPE to remain a **plug-and-play solution**, i.e., not needing an additional fine-tuning stage, the authors trim all high dim indices that are larger than the $L_{window}$ hyperparameter.

_Comment_: show on the image.

The distribution of position indices over the attention matrix can also be seen here.
#### HiRoPE: Results

_Comment_: mention the tables from the article, the statement about the exponential increase in extrapolation abilities.
#### HiRoPE: Doubts

_Comment_: just go through slide.