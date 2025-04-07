# LEARNING PYTHON CODE SUGGESTION WITH A SPARSE POINTER NETWORK

Avishkar Bhoopchand, Tim Rocktaschel, Earl Barr & Sebastian Riedel ¨ Department of Computer Science University College London avishkar.bhoopchand.15@ucl.ac.uk, {t.rocktaschel,e.barr,s.riedel}@cs.ucl.ac.uk

## ABSTRACT

To enhance developer productivity, all modern integrated development environments (IDEs) include *code suggestion* functionality that proposes likely next tokens at the cursor. While current IDEs work well for statically-typed languages, their reliance on type annotations means that they do not provide the same level of support for dynamic programming languages as for statically-typed languages. Moreover, suggestion engines in modern IDEs do not propose expressions or multi-statement idiomatic code. Recent work has shown that language models can improve code suggestion systems by learning from software repositories. This paper introduces a neural language model with a sparse pointer network aimed at capturing very longrange dependencies. We release a large-scale code suggestion corpus of 41M lines of Python code crawled from GitHub. On this corpus, we found standard neural language models to perform well at suggesting local phenomena, but struggle to refer to identifiers that are introduced many tokens in the past. By augmenting a neural language model with a pointer network specialized in referring to predefined classes of identifiers, we obtain a much lower perplexity and a 5 percentage points increase in accuracy for code suggestion compared to an LSTM baseline. In fact, this increase in code suggestion accuracy is due to a 13 times more accurate prediction of identifiers. Furthermore, a qualitative analysis shows this model indeed captures interesting long-range dependencies, like referring to a class member defined over 60 tokens in the past.

## 1 INTRODUCTION

Integrated development environments (IDEs) are essential tools for programmers. Especially when a developer is new to a codebase, one of their most useful features is code suggestion: given a piece of code as context, suggest a likely sequence of next tokens. Typically, the IDE suggests an identifier or a function call, including API calls. While extensive support exists for statically-typed languages such as Java, code suggestion for dynamic languages like Python is harder and less well supported because of the lack of type annotations. Moreover, suggestion engines in modern IDEs do not propose expressions or multi-statement idiomatic code.

Recently, methods from statistical natural language processing (NLP) have been used to train code suggestion systems from code usage in large code repositories [\(Hindle et al.,](#page-8-0) [2012;](#page-8-0) [Allamanis &](#page-7-0) [Sutton,](#page-7-0) [2013;](#page-7-0) [Tu et al.,](#page-9-0) [2014\)](#page-9-0). To this end, usually an n-gram language model is trained to score possible completions. Neural language models for code suggestion [\(White et al.,](#page-9-1) [2015;](#page-9-1) [Das &](#page-8-1) [Shah,](#page-8-1) [2015\)](#page-8-1) have extended this line of work to capture more long-range dependencies. Yet, these standard neural language models are limited by the so-called hidden state bottleneck, *i.e.*, all context information has to be stored in a fixed-dimensional internal vector representation. This limitation restricts such models to local phenomena and does not capture very long-range semantic relationships like suggesting calling a function that has been defined many tokens before.

To address these issues, we create a large corpus of 41M lines of Python code by using a heuristic for crawling high-quality code repositories from GitHub. We investigate, for the first time, the use of attention [\(Bahdanau et al.,](#page-7-1) [2014\)](#page-7-1) for code suggestion and find that, despite a substantial improvement in accuracy, it still makes avoidable mistakes. Hence, we introduce a model that leverages long-range Python dependencies by selectively attending over the introduction of identifiers as determined by examining the Abstract Syntax Tree. The model is a form of pointer network [\(Vinyals et al.,](#page-9-2) [2015a\)](#page-9-2), and learns to dynamically choose between syntax-aware pointing for modeling long-range dependencies and free form generation to deal with local phenomena, based on the current context.

Our contributions are threefold: (i) We release a code suggestion corpus of 41M lines of Python code crawled from GitHub, (ii) We introduce a sparse attention mechanism that captures very long-range dependencies for code suggestion of this dynamic programming language efficiently, and (iii) We provide a qualitative analysis demonstrating that this model is indeed able to learn such long-range dependencies.

## 2 METHODS

We first revisit neural language models, before briefly describing how to extend such a language model with an attention mechanism. Then we introduce a sparse attention mechanism for a pointer network that can exploit the Python abstract syntax tree of the current context for code suggestion.

#### 2.1 NEURAL LANGUAGE MODEL

Code suggestion can be approached by a language model that measures the probability of observing a sequence of tokens in a Python program. For example, for the sequence S = a1, . . . , a<sup>N</sup> , the joint probability of S factorizes according to

<span id="page-1-0"></span>
$$P\_{\theta}(S) = P\_{\theta}(a\_1) \cdot \prod\_{t=2}^{N} P\_{\theta}(a\_t \mid a\_{t-1}, \dots, a\_1) \tag{l}$$

where the parameters θ are estimated from a training corpus. Given a sequence of Python tokens, we seek to predict the next M tokens at+1, . . . , at+<sup>M</sup> that maximize [Equation 1](#page-1-0)

$$\underset{a\_{t+1},...,a\_{t+M}}{\arg\max} \ P\_{\theta}(a\_1,...,...,a\_t, \ a\_{t+1},..., \ a\_{t+M}).\tag{2}$$

In this work, we build upon neural language models using Recurrent Neural Networks (RNNs) and Long Short-Term Memory (LSTM, [Hochreiter & Schmidhuber,](#page-8-2) [1997\)](#page-8-2). This neural language model estimates the probabilities in [Equation 1](#page-1-0) using the output vector of an LSTM at time step t (denoted h<sup>t</sup> here) according to

$$P\_{\theta}(a\_t = \tau \mid a\_{t-1}, \dots, a\_1) = \frac{\exp\left(\boldsymbol{v}\_{\tau}^T \boldsymbol{h}\_t + b\_{\tau}\right)}{\sum\_{\tau'} \exp\left(\boldsymbol{v}\_{\tau}^T \boldsymbol{h}\_t + b\_{\tau'}\right)}\tag{3}$$

where v<sup>τ</sup> is a parameter vector associated with token τ in the vocabulary.

Neural language models can, in theory, capture long-term dependencies in token sequences through their internal memory. However, as this internal memory has fixed dimension and can be updated at every time step, such models often only capture local phenomena. In contrast, we are interested in very long-range dependencies like referring to a function identifier introduced many tokens in the past. For example, a function identifier may be introduced at the top of a file and only used near the bottom. In the following, we investigate various external memory architectures for neural code suggestion.

#### 2.2 ATTENTION

A straight-forward approach to capturing long-range dependencies is to use a neural attention mechanism [\(Bahdanau et al.,](#page-7-1) [2014\)](#page-7-1) on the previous K output vectors of the language model. Attention mechanisms have been successfully applied to sequence-to-sequence tasks such as machine translation [\(Bahdanau et al.,](#page-7-1) [2014\)](#page-7-1), question-answering [\(Hermann et al.,](#page-8-3) [2015\)](#page-8-3), syntactic parsing [\(Vinyals](#page-9-3) [et al.,](#page-9-3) [2015b\)](#page-9-3), as well as dual-sequence modeling like recognizing textual entailment [\(Rocktaschel](#page-9-4) ¨ [et al.,](#page-9-4) [2016\)](#page-9-4). The idea is to overcome the hidden-state bottleneck by allowing referral back to previous output vectors. Recently, these mechanisms were applied to language modelling by [Cheng et al.](#page-8-4) [\(2016\)](#page-8-4) and [Tran et al.](#page-9-5) [\(2016\)](#page-9-5).

Formally, an attention mechanism with a fixed memory M<sup>t</sup> ∈ R <sup>k</sup>×<sup>K</sup> of K vectors m<sup>i</sup> ∈ R k for i ∈ [1, K], produces an attention distribution α<sup>t</sup> ∈ R <sup>K</sup> and context vector c<sup>t</sup> ∈ R k at each time step t according to Equations [4](#page-2-0) to [7.](#page-2-1) Furthermore, WM,W<sup>h</sup> ∈ R k×k and w ∈ R k are trainable parameters. Finally, note that 1<sup>K</sup> represents a K-dimensional vector of ones.

$$M\_t = [m\_1 \ \ldots \ m\_K] \tag{4}$$

<span id="page-2-0"></span>
$$\mathbf{G}\_t = \tanh(\mathbf{W}^M \mathbf{M}\_t + \mathbf{1}\_K^T(\mathbf{W}^h \mathbf{h}\_t)) \tag{5}$$

$$\alpha\_t = \text{softmax}(w^T \mathbf{G}\_t) \tag{6}$$

<span id="page-2-1"></span>
$$\mathbf{c}\_t = \mathbf{M}\_t \mathbf{\alpha}\_t^T \tag{7}$$

For language modeling, we populate M<sup>t</sup> with a fixed window of the previous K LSTM output vectors. To obtain a distribution over the next token we combine the context vector c<sup>t</sup> of the attention mechanism with the output vector h<sup>t</sup> of the LSTM using a trainable projection matrix W<sup>A</sup> ∈ R k×2k . The resulting final output vector n<sup>t</sup> ∈ R k encodes the next-word distribution and is projected to the size of the vocabulary |V |. Subsequently, we apply a softmax to arrive at a probability distribution y<sup>t</sup> ∈ R <sup>|</sup><sup>V</sup> <sup>|</sup> over the next token. This process is presented in [Equation 9](#page-2-2) where W<sup>V</sup> ∈ R |V |×k and b <sup>V</sup> ∈ R |V | are trainable parameters.

$$m\_t = \tanh\left(\mathbf{W}^A \begin{bmatrix} \mathbf{h}\_t \\ \mathbf{c}\_t \end{bmatrix}\right) \tag{8}$$

<span id="page-2-2"></span>
$$y\_t = \text{softmax}(\mathbf{W}^V \mathbf{n}\_t + \mathbf{b}^V) \tag{9}$$

The problem of the attention mechanism above is that it quickly becomes computationally expensive for large K. Moreover, attending over many memories can make training hard as a lot of noise is introduced in early stages of optimization where the LSTM outputs (and thus the memory Mt) are more or less random. To alleviate these problems we now turn to pointer networks and a simple heuristic for populating M<sup>t</sup> that permits the efficient retrieval of identifiers in a large history of Python code.

#### 2.3 SPARSE POINTER NETWORK

We develop an attention mechanism that provides a *filtered view* of a large history of Python tokens. At any given time step, the memory consists of context representations of the previous K identifiers introduced in the history. This allows us to model long-range dependencies found in identifier usage. For instance, a class identifier may be declared hundreds of lines of code before it is used. Given a history of Python tokens, we obtain a next-word distribution from a weighed average of the sparse pointer network for identifier reference and a standard neural language model. The weighting of the two is determined by a controller.

Formally, at time-step t, the sparse pointer network operates on a memory M<sup>t</sup> ∈ R <sup>k</sup>×<sup>K</sup> of only the K previous identifier representations (*e.g.* function identifiers, class identifiers and so on). In addition, we maintain a vector m<sup>t</sup> = [id1, . . . , idK] ∈ N <sup>K</sup> of symbol ids for these identifier representations (*i.e.* pointers into the large global vocabulary).

As before, we calculate a context vector c<sup>t</sup> using the attention mechanism [\(Equation 7\)](#page-2-1), but on a memory M<sup>t</sup> only containing representations of identifiers that were declared in the history. Next, we obtain a pseudo-sparse distribution over the global vocabulary from

$$\mathbf{s}\_t[i] = \begin{cases} \alpha\_t[j] & \text{if } m\_t[j] = i \\ -C & \text{otherwise} \end{cases} \tag{10}$$

$$\dot{\mathfrak{a}}\_t = \text{softmax}(\mathfrak{s}\_t) \tag{11}$$

where −C is a large negative constant (*e.g.* −1000). In addition, we calculate a next-word distribution from a standard neural language model

$$y\_t = \text{softmax}(\mathbf{W}^V \mathbf{h}\_t + \mathbf{b}^V) \tag{12}$$

<span id="page-3-0"></span>![](_page_3_Figure_1.jpeg)

Figure 1: Sparse pointer network for code suggestion on a Python code snippet, showing the nextword distributions of the language model and identifier attention and their weighted combination through λ

and we use a controller to calculate a distribution λ<sup>t</sup> ∈ R <sup>2</sup> over the language model and pointer network for the final weighted next-word distribution y ∗ <sup>t</sup> via

$$h\_t^\lambda = \begin{bmatrix} h\_t \\ \mathbf{x}\_t \\ \mathbf{c}\_t \end{bmatrix} \tag{13}$$

$$\lambda\_t = \text{softmax}(\mathbf{W}^\lambda \mathbf{h}\_t^\lambda + \mathbf{b}^\lambda) \tag{14}$$

$$y\_t^\* = \begin{bmatrix} y\_t \ i\_t \end{bmatrix} \lambda\_t \tag{15}$$

Here, x<sup>t</sup> is the representation of the input token, and W<sup>λ</sup> ∈ R 2×3k and b <sup>λ</sup> ∈ R 2 a trainable weight matrix and bias respectively. This controller is conditioned on the input, output and context representations. This means for deciding whether to refer to an identifier or generate from the global vocabulary, the controller has access to information from the encoded next-word distribution h<sup>t</sup> of the standard neural language model, as well as the attention-weighted identifier representations c<sup>t</sup> from the current history.

[Figure 1](#page-3-0) overviews this process. In it, the identifier base\_path appears twice, once as an argument to a function and once as a member of a class (denoted by \*). Each appearance has a different id in the vocabulary and obtains a different probability from the model. In the example, the model correctly chooses to refer to the member of the class instead of the out-of-scope function argument, although, from a user point-of-view, the suggestion would be the same in both cases.

## 3 LARGE-SCALE PYTHON CORPUS

Previous work on code suggestion either focused on statically-typed languages (particularly Java) or trained on very small corpora. Thus, we decided to collect a new large-scale corpus of the dynamic programming language Python. According to the programming language popularity website Pypl [\(Carbonnelle,](#page-8-5) [2016\)](#page-8-5), Python is the second most popular language after Java. It is also the 3rd most common language in terms of number of repositories on the open-source code repository GitHub, after JavaScript and Java [\(Zapponi,](#page-9-6) [2016\)](#page-9-6).

We collected a corpus of 41M lines of Python code from GitHub projects. Ideally, we would like this corpus to only contain high-quality Python code, as our language model learns to suggest code from how users write code. However, it is difficult to automatically assess what constitutes high-quality code. Thus, we resort to the heuristic that popular code projects tend to be of good quality, There are

<span id="page-4-0"></span>

| Dataset | #Projects | #Files  | #Lines     | #Tokens     | Vocabulary Size |
|---------|-----------|---------|------------|-------------|-----------------|
| Train   | 489       | 118 298 | 26 868 583 | 88 935 698  | 2 323 819       |
| Dev     | 179       | 26 466  | 5 804 826  | 18 147 341  |                 |
| Test    | 281       | 43 062  | 8 398 100  | 30 178 356  |                 |
| Total   | 949       | 187 826 | 41 071 509 | 137 261 395 |                 |

Table 1: Python corpus statistics.

![](_page_4_Figure_3.jpeg)

Figure 2: Example of the Python code normalization. Original file on the left and normalized version on the right.

two metrics on GitHub that we can use for this purpose, namely stars (similar to bookmarks) and forks (copies of a repository that allow users to freely experiment with changes without affecting the original repository). Similar to [Allamanis & Sutton](#page-7-0) [\(2013\)](#page-7-0) and [Allamanis et al.](#page-7-2) [\(2014\)](#page-7-2), we select Python projects with more than 100 stars, sort by the number of forks descending, and take the top 1000 projects. We then removed projects that did not compile with Python3, leaving us with 949 projects. We split the corpus on the project level into train, dev, and test. [Table 1](#page-4-0) presents the corpus statistics.

#### 3.1 NORMALIZATION OF IDENTIFIERS

Unsurprisingly, the long tail of words in the vocabulary consists of rare identifiers. To improve generalization, we normalize identifiers before feeding the resulting token stream to our models. That is, we replace every identifier name with an anonymous identifier indicating the identifier group (class, variable, argument, attribute or function) concatenated with a random number that makes the identifier unique in its scope. Note that we only replace novel identifiers defined within a file. Identifier references to external APIs and libraries are left untouched. Consistent with previous corpus creation for code suggestion (*e.g.* [Khanh Dam et al.,](#page-8-6) [2016;](#page-8-6) [White et al.,](#page-9-1) [2015\)](#page-9-1), we replace numerical constant tokens with \$NUM\$, remove comments, reformat the code, and replace tokens appearing less than five times with an \$OOV\$ (out of vocabulary) token.

## 4 EXPERIMENTS

Although previous work by [White et al.](#page-9-1) [\(2015\)](#page-9-1) already established that a simple neural language model outperforms an n-gram model for code suggestion, we include a number of n-gram baselines to confirm this observation. Specifically, we use n-gram models for n ∈ {3, 4, 5, 6} with Modified Kneser-Ney smoothing [\(Kneser & Ney,](#page-8-7) [1995\)](#page-8-7) from the Kyoto Language Modelling Toolkit [\(Neubig,](#page-8-8) [2012\)](#page-8-8).

We train the sparse pointer network using mini-batch SGD with a batch size of 30 and truncated backpropagation through time [\(Werbos,](#page-9-7) [1990\)](#page-9-7) with a history of 20 identifier representations. We use

| Model                  | Train PP | Dev PP | Test PP | Acc [%] |      | Acc@5 [%] |       |      |       |
|------------------------|----------|--------|---------|---------|------|-----------|-------|------|-------|
|                        |          |        |         | All     | IDs  | Other     | All   | IDs  | Other |
| 3-gram                 | 12.90    | 24.19  | 26.90   | 13.19   | –    | –         | 50.81 | –    | –     |
| 4-gram                 | 7.60     | 21.07  | 23.85   | 13.68   | –    | –         | 51.26 | –    | –     |
| 5-gram                 | 4.52     | 19.33  | 21.22   | 13.90   | –    | –         | 51.49 | –    | –     |
| 6-gram                 | 3.37     | 18.73  | 20.17   | 14.51   | –    | –         | 51.76 | –    | –     |
| LSTM                   | 9.29     | 13.08  | 14.01   | 57.91   | 2.1  | 62.8      | 76.30 | 4.5  | 82.6  |
| LSTM w/ Attention 20   | 7.30     | 11.07  | 11.74   | 61.30   | 21.4 | 64.8      | 79.32 | 29.9 | 83.7  |
| LSTM w/ Attention 50   | 7.09     | 9.83   | 10.05   | 63.21   | 30.2 | 65.3      | 81.69 | 41.3 | 84.1  |
| Sparse Pointer Network | 6.41     | 9.40   | 9.18    | 62.97   | 27.3 | 64.9      | 82.62 | 43.6 | 84.5  |

<span id="page-5-0"></span>

| Table 2: Perplexity (PP), Accuracy (Acc) and Accuarcy among top 5 predictions (Acc@5). |  |  |  |  |
|----------------------------------------------------------------------------------------|--|--|--|--|
|----------------------------------------------------------------------------------------|--|--|--|--|

an initial learning rate of 0.7 and decay it by 0.9 after every epoch. As additional baselines, we test a neural language model with LSTM units with and without attention. For the attention language models, we experiment with a fixed-window attention memory of the previous 20 and 50 tokens respectively, and a batch size of 75.

All neural language models were developed in TensorFlow [\(Abadi et al.,](#page-7-3) [2016\)](#page-7-3) and trained using cross-entropy loss. While processing a Python source code file, the last recurrent state of the RNN is fed as the initial state of the subsequent sequence of the same file and reset between files. All models use an input and hidden size of 200, an LSTM forget gate bias of 1 [\(Jozefowicz et al.,](#page-8-9) [2015\)](#page-8-9), gradient norm clipping of 5 [\(Pascanu et al.,](#page-9-8) [2013\)](#page-9-8), and randomly initialized parameters in the interval (−0.05, 0.05). As regularizer, we use a dropout of 0.1 on the input representations. Furthermore, we use a sampled softmax [\(Jean et al.,](#page-8-10) [2015\)](#page-8-10) with a log-uniform sampling distribution and a sample size of 1000.

## 5 RESULTS

We evaluate all models using perplexity (PP), as well as accuracy of the top prediction (Acc) and the top five predictions (Acc@5). The results are summarized in [Table 2.](#page-5-0)

We can confirm that for code suggestion neural models outperform n-gram language models by a large margin. Furthermore, adding attention improves the results substantially (2.3 lower perplexity and 3.4 percentage points increased accuracy). Interestingly, this increase can be attributed to a superior prediction of identifiers, which increased from an accuracy of 2.1% to 21.4%. An LSTM with an attention window of 50 gives us the best accuracy for the top prediction. We achieve further improvements for perplexity and accuracy of the top five predictions by using a sparse pointer network that uses a smaller memory of the past 20 identifier representations.

#### 5.1 QUALITATIVE ANALYSIS

Figures [3a](#page-6-0)-d show a code suggestion example involving an identifier usage. While the LSTM baseline is uncertain about the next token, we get a sensible prediction by using attention or the sparse pointer network. The sparse pointer network provides more reasonable alternative suggestions beyond the correct top suggestion.

Figures [3e](#page-6-0)-h show the use-case referring to a class attribute declared 67 tokens in the past. Only the Sparse Pointer Network makes a good suggestion. Furthermore, the attention weights in [3i](#page-6-0) demonstrate that this model distinguished attributes from other groups of identifiers. We give a full example of a token-by-token suggestion of the Sparse Pointer Network in [Figure 4](#page-10-0) in the Appendix.

# 6 RELATED WORK

Previous code suggestion work using methods from statistical NLP has mostly focused on n-gram models. Much of this work is inspired by [Hindle et al.](#page-8-0) [\(2012\)](#page-8-0) who argued that real programs fall

<span id="page-6-0"></span>

| (a) Code snippet for referencing<br>variable.     | (b) LSTM Model. | (c) LSTM w/ Attention<br>50. | (d) Sparse Pointer Net<br>work. |
|---------------------------------------------------|-----------------|------------------------------|---------------------------------|
|                                                   |                 |                              |                                 |
|                                                   |                 |                              |                                 |
|                                                   |                 |                              |                                 |
|                                                   |                 |                              |                                 |
| (e) Code snippet for referencing class<br>member. | (f) LSTM Model. | (g) LSTM w/ Attention<br>50. | (h) Sparse Pointer Net<br>work. |
|                                                   |                 |                              |                                 |

(i) Sparse Pointer Network attention over memory of identifier representations.

Figure 3: Code suggestion example involving a reference to a variable (a-d), a long-range dependency (e-h), and the attention weights of the Sparse Pointer Network (i).

into a much smaller space than the flexibility of programming languages allows. They were able to capture the repetitiveness and predictable statistical properties of real programs using language models. Subsequently, [Tu et al.](#page-9-0) [\(2014\)](#page-9-0) improved upon [Hindle et al.'](#page-8-0)s work by adding a cache mechanism that allowed them to exploit locality stemming from the specialisation and decoupling of program modules. [Tu et al.'](#page-9-0)s idea of adding a cache mechanism to the language model is specifically designed to exploit the properties of source code, and thus follows the same aim as the sparse attention mechanism introduced in this paper.

While the majority of preceding work trained on small corpora, [Allamanis & Sutton](#page-7-0) [\(2013\)](#page-7-0) created a corpus of 352M lines of Java code which they analysed with n-gram language models. The size of the corpus allowed them to train a single language model that was effective across multiple different project domains. [White et al.](#page-9-1) [\(2015\)](#page-9-1) later demonstrated that neural language models outperform n-gram models for code suggestion. They compared various n-gram models (up to nine grams), including [Tu et al.'](#page-9-0)s cache model, with a basic RNN neural language model. [Khanh Dam et al.](#page-8-6) [\(2016\)](#page-8-6) compared [White et al.'](#page-9-1)s basic RNN with LSTMs and found that the latter are better at code suggestion due to their improved ability to learn long-range dependencies found in source code. Our paper extends this line of work by introducing a sparse attention model that captures even longer dependencies.

The combination of lagged attention mechanisms with language modelling is inspired by [Cheng et al.](#page-8-4) [\(2016\)](#page-8-4) who equipped LSTM cells with a fixed-length memory tape rather than a single memory cell. They achieved promising results on the standard Penn Treebank benchmark corpus [\(Marcus et al.,](#page-8-11) [1993\)](#page-8-11). Similarly, [Tran et al.](#page-9-5) added a *memory block* to LSTMs for language modelling of English, German and Italian and outperformed both n-gram and neural language models. Their memory encompasses representations of all possible words in the vocabulary rather than providing a sparse view as we do.

An alternative to our purely lexical approach to code suggestion involves the use of probabilistic context-free grammars (PCFGs) which exploit the formal grammar specifications and well-defined, deterministic parsers available for source code. These were used by [Allamanis & Sutton](#page-7-4) [\(2014\)](#page-7-4) to extract idiomatic patterns from source code. A weakness of PCFGs is their inability to model context-dependent rules of programming languages such as that variables need to be declared before

being used. [Maddison & Tarlow](#page-8-12) [\(2014\)](#page-8-12) added context-aware variables to their PCFG model in order to capture such rules.

[Ling et al.](#page-8-13) [\(2016\)](#page-8-13) recently used a pointer network to generate code from natural language descriptions. Our use of a controller for deciding whether to generate from a language model or copy an identifier using a sparse pointer network is inspired by their latent code predictor. However, their inputs (textual descriptions) are short whereas code suggestion requires capturing very long-range dependencies that we addressed by a filtered view on the memory of previous identifier representations.

## 7 CONCLUSIONS AND FUTURE WORK

In this paper, we investigated neural language models for code suggestion of the dynamically-typed programming language Python. We released a corpus of 41M lines of Python crawled from GitHub and compared n-gram, standard neural language models, and attention. By using attention, we observed an order of magnitude more accurate prediction of identifiers. Furthermore, we proposed a sparse pointer network that can efficiently capture long-range dependencies by only operating on a filtered view of a memory of previous identifier representations. This model achieves the lowest perplexity and best accuracy among the top five predictions. The Python corpus and code for replicating our experiment is released at <https://github.com/uclmr/pycodesuggest>.

The presented methods were only tested for code suggestion within the same Python file. We are interested in scaling the approach to the level of entire code projects and collections thereof, as well as integrating a trained code suggestion model into an existing IDE. Furthermore, we plan to work on code completion, *i.e.*, models that provide a likely continuation of a partial token, using character language models [\(Graves,](#page-8-14) [2013\)](#page-8-14).

#### ACKNOWLEDGMENTS

This work was supported by Microsoft Research through its PhD Scholarship Programme, an Allen Distinguished Investigator Award, and a Marie Curie Career Integration Award.

## REFERENCES

- <span id="page-7-3"></span>Mart´ın Abadi, Paul Barham, Jianmin Chen, Zhifeng Chen, Andy Davis, Jeffrey Dean, Matthieu Devin, Sanjay Ghemawat, Geoffrey Irving, Michael Isard, Manjunath Kudlur, Josh Levenberg, Rajat Monga, Sherry Moore, Derek Gordon Murray, Benoit Steiner, Paul A. Tucker, Vijay Vasudevan, Pete Warden, Martin Wicke, Yuan Yu, and Xiaoqiang Zhang. Tensorflow: A system for large-scale machine learning. *CoRR*, abs/1605.08695, 2016. URL [http://arxiv.org/abs/1605.](http://arxiv.org/abs/1605.08695) [08695](http://arxiv.org/abs/1605.08695).
- <span id="page-7-4"></span>Miltiadis Allamanis and Charles Sutton. Mining idioms from source code. In *Proceedings of the 22Nd ACM SIGSOFT International Symposium on Foundations of Software Engineering*, FSE 2014, pp. 472–483, New York, NY, USA, 2014. ACM. ISBN 978-1-4503-3056-5. doi: 10.1145/2635868.2635901. URL <http://doi.acm.org/10.1145/2635868.2635901>.
- <span id="page-7-0"></span>Miltiadis Allamanis and Charles A. Sutton. Mining source code repositories at massive scale using language modeling. In Thomas Zimmermann, Massimiliano Di Penta, and Sunghun Kim (eds.), *MSR*, pp. 207–216. IEEE Computer Society, 2013. ISBN 978-1-4673-2936-1. URL <http://dblp.uni-trier.de/db/conf/msr/msr2013.html#AllamanisS13a>.
- <span id="page-7-2"></span>Miltiadis Allamanis, Earl T. Barr, Christian Bird, and Charles Sutton. Learning natural coding conventions. In *Proceedings of the 22Nd ACM SIGSOFT International Symposium on Foundations of Software Engineering*, FSE 2014, pp. 281–293, New York, NY, USA, 2014. ACM. ISBN 978- 1-4503-3056-5. doi: 10.1145/2635868.2635883. URL [http://doi.acm.org/10.1145/](http://doi.acm.org/10.1145/2635868.2635883) [2635868.2635883](http://doi.acm.org/10.1145/2635868.2635883).
- <span id="page-7-1"></span>Dzmitry Bahdanau, Kyunghyun Cho, and Yoshua Bengio. Neural machine translation by jointly learning to align and translate. *CoRR*, abs/1409.0473, 2014. URL [http://arxiv.org/abs/](http://arxiv.org/abs/1409.0473) [1409.0473](http://arxiv.org/abs/1409.0473).
- <span id="page-8-5"></span>Pierre Carbonnelle. Pypl popularity of programming language. [http://pypl.github.io/](http://pypl.github.io/PYPL.html) [PYPL.html](http://pypl.github.io/PYPL.html), 2016. URL <http://pypl.github.io/PYPL.html>. [Online; accessed 30- August-2016].
- <span id="page-8-4"></span>Jianpeng Cheng, Li Dong, and Mirella Lapata. Long short-term memory-networks for machine reading. In *Proceedings of the 2016 Conference on Empirical Methods in Natural Language Processing*, pp. 551–561. Association for Computational Linguistics, 2016. URL [http://](http://aclweb.org/anthology/D16-1053) [aclweb.org/anthology/D16-1053](http://aclweb.org/anthology/D16-1053).

<span id="page-8-1"></span>Subhasis Das and Chinmayee Shah. Contextual code completion using machine learning. 2015.

- <span id="page-8-14"></span>Alex Graves. Generating sequences with recurrent neural networks. *CoRR*, abs/1308.0850, 2013. URL <http://arxiv.org/abs/1308.0850>.
- <span id="page-8-3"></span>Karl Moritz Hermann, Tomas Kocisk ´ y, Edward Grefenstette, Lasse Espeholt, Will Kay, ´ Mustafa Suleyman, and Phil Blunsom. Teaching machines to read and comprehend. In *Advances in Neural Information Processing Systems 28: Annual Conference on Neural Information Processing Systems 2015, December 7-12, 2015, Montreal, Quebec, Canada*, pp. 1693–1701, 2015. URL [http://papers.nips.cc/paper/](http://papers.nips.cc/paper/5945-teaching-machines-to-read-and-comprehend) [5945-teaching-machines-to-read-and-comprehend](http://papers.nips.cc/paper/5945-teaching-machines-to-read-and-comprehend).
- <span id="page-8-0"></span>Abram Hindle, Earl T. Barr, Zhendong Su, Mark Gabel, and Premkumar Devanbu. On the naturalness of software. In *Proceedings of the 34th International Conference on Software Engineering*, ICSE '12, pp. 837–847, Piscataway, NJ, USA, 2012. IEEE Press. ISBN 978-1-4673-1067-3. URL <http://dl.acm.org/citation.cfm?id=2337223.2337322>.
- <span id="page-8-2"></span>Sepp Hochreiter and Jurgen Schmidhuber. Long short-term memory. ¨ *Neural Comput.*, 9(8):1735– 1780, November 1997. ISSN 0899-7667. doi: 10.1162/neco.1997.9.8.1735. URL [http://dx.](http://dx.doi.org/10.1162/neco.1997.9.8.1735) [doi.org/10.1162/neco.1997.9.8.1735](http://dx.doi.org/10.1162/neco.1997.9.8.1735).
- <span id="page-8-10"></span>Sebastien Jean, Kyunghyun Cho, Roland Memisevic, and Yoshua Bengio. On using very large target ´ vocabulary for neural machine translation. In *Proceedings of the 53rd Annual Meeting of the Association for Computational Linguistics and the 7th International Joint Conference on Natural Language Processing (Volume 1: Long Papers)*, pp. 1–10, Beijing, China, July 2015. Association for Computational Linguistics. URL <http://www.aclweb.org/anthology/P15-1001>.
- <span id="page-8-9"></span>Rafal Jozefowicz, Wojciech Zaremba, and Ilya Sutskever. An empirical exploration of recurrent network architectures. In David Blei and Francis Bach (eds.), *Proceedings of the 32nd International Conference on Machine Learning (ICML-15)*, pp. 2342–2350. JMLR Workshop and Conference Proceedings, 2015. URL [http://jmlr.org/proceedings/papers/v37/](http://jmlr.org/proceedings/papers/v37/jozefowicz15.pdf) [jozefowicz15.pdf](http://jmlr.org/proceedings/papers/v37/jozefowicz15.pdf).
- <span id="page-8-6"></span>H. Khanh Dam, T. Tran, and T. Pham. A deep language model for software code. *ArXiv e-prints*, August 2016.
- <span id="page-8-7"></span>R. Kneser and H. Ney. Improved backing-off for m-gram language modeling. In *Acoustics, Speech, and Signal Processing, 1995. ICASSP-95., 1995 International Conference on*, volume 1, pp. 181–184 vol.1, May 1995. doi: 10.1109/ICASSP.1995.479394.
- <span id="page-8-13"></span>Wang Ling, Edward Grefenstette, Karl Moritz Hermann, Tomas Kocisky, Andrew Senior, Fumin Wang, and Phil Blunsom. Latent predictor networks for code generation. *arXiv preprint arXiv:1603.06744*, 2016.
- <span id="page-8-12"></span>Chris J Maddison and Daniel Tarlow. Structured generative models of natural source code. In *International Conference on Machine Learning*, 2014.
- <span id="page-8-11"></span>Mitchell P. Marcus, Beatrice Santorini, and Mary Ann Marcinkiewicz. Building a large annotated corpus of english: The penn treebank. *COMPUTATIONAL LINGUISTICS*, 19(2):313–330, 1993.
- <span id="page-8-8"></span>Graham Neubig. Kylm - the kyoto language modeling toolkit. [http://www.phontron.com/](http://www.phontron.com/kylm/) [kylm/](http://www.phontron.com/kylm/), 2012. URL <http://www.phontron.com/kylm/>. [Online; accessed 23-July-2016].
- <span id="page-9-8"></span>Razvan Pascanu, Tomas Mikolov, and Yoshua Bengio. On the difficulty of training recurrent neural networks. In *Proceedings of the 30th International Conference on Machine Learning, ICML 2013, Atlanta, GA, USA, 16-21 June 2013*, pp. 1310–1318, 2013. URL [http://jmlr.org/](http://jmlr.org/proceedings/papers/v28/pascanu13.html) [proceedings/papers/v28/pascanu13.html](http://jmlr.org/proceedings/papers/v28/pascanu13.html).
- <span id="page-9-4"></span>Tim Rocktaschel, Edward Grefenstette, Karl Moritz Hermann, Tomas Kocisky, and Phil Blunsom. ¨ Reasoning about entailment with neural attention. In *ICLR*, 2016.
- <span id="page-9-5"></span>Ke M. Tran, Arianna Bisazza, and Christof Monz. Recurrent memory networks for language modeling. In *NAACL HLT 2016, The 2016 Conference of the North American Chapter of the Association for Computational Linguistics: Human Language Technologies, San Diego California, USA, June 12-17, 2016*, pp. 321–331, 2016. URL [http://aclweb.org/anthology/N/](http://aclweb.org/anthology/N/N16/N16-1036.pdf) [N16/N16-1036.pdf](http://aclweb.org/anthology/N/N16/N16-1036.pdf).
- <span id="page-9-0"></span>Zhaopeng Tu, Zhendong Su, and Premkumar Devanbu. On the localness of software. In *Proceedings of the 22Nd ACM SIGSOFT International Symposium on Foundations of Software Engineering*, FSE 2014, pp. 269–280, New York, NY, USA, 2014. ACM. ISBN 978-1-4503-3056-5. doi: 10.1145/2635868.2635875. URL <http://doi.acm.org/10.1145/2635868.2635875>.
- <span id="page-9-2"></span>Oriol Vinyals, Meire Fortunato, and Navdeep Jaitly. Pointer networks. In *Advances in Neural Information Processing Systems*, pp. 2692–2700, 2015a.
- <span id="page-9-3"></span>Oriol Vinyals, Lukasz Kaiser, Terry Koo, Slav Petrov, Ilya Sutskever, and Geoffrey E. Hinton. Grammar as a foreign language. In *Advances in Neural Information Processing Systems 28: Annual Conference on Neural Information Processing Systems 2015, December 7-12, 2015, Montreal, Quebec, Canada*, pp. 2773–2781, 2015b. URL [http://papers.nips.cc/paper/](http://papers.nips.cc/paper/5635-grammar-as-a-foreign-language) [5635-grammar-as-a-foreign-language](http://papers.nips.cc/paper/5635-grammar-as-a-foreign-language).
- <span id="page-9-7"></span>Paul J Werbos. Backpropagation through time: what it does and how to do it. *Proceedings of the IEEE*, 78(10):1550–1560, 1990.
- <span id="page-9-1"></span>Martin White, Christopher Vendome, Mario Linares-Vasquez, and Denys Poshyvanyk. Toward ´ deep learning software repositories. In *Proceedings of the 12th Working Conference on Mining Software Repositories*, MSR '15, pp. 334–345, Piscataway, NJ, USA, 2015. IEEE Press. URL <http://dl.acm.org/citation.cfm?id=2820518.2820559>.
- <span id="page-9-6"></span>Carlo Zapponi. Githut - programming languages and github. <http://githut.info/>, 2016. URL <http://githut.info/>. [Online; accessed 19-August-2016].

## <span id="page-10-0"></span>APPENDIX

![](_page_10_Figure_2.jpeg)

Figure 4: Full example of code suggestion with a Sparse Pointer Network. Boldface tokens on the left show the first declaration of an identifier. The middle part visualizes the memory of representations of these identifiers. The right part visualizes the output λ of the controller, which is used for interpolating between the language model (LM) and the attention of the pointer network (Att).