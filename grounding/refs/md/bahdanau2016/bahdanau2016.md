# NEURAL MACHINE TRANSLATION BY JOINTLY LEARNING TO ALIGN AND TRANSLATE

Dzmitry Bahdanau

Jacobs University Bremen, Germany

KyungHyun Cho Yoshua Bengio<sup>∗</sup> Universite de Montr ´ eal ´

### ABSTRACT

Neural machine translation is a recently proposed approach to machine translation. Unlike the traditional statistical machine translation, the neural machine translation aims at building a single neural network that can be jointly tuned to maximize the translation performance. The models proposed recently for neural machine translation often belong to a family of encoder–decoders and encode a source sentence into a fixed-length vector from which a decoder generates a translation. In this paper, we conjecture that the use of a fixed-length vector is a bottleneck in improving the performance of this basic encoder–decoder architecture, and propose to extend this by allowing a model to automatically (soft-)search for parts of a source sentence that are relevant to predicting a target word, without having to form these parts as a hard segment explicitly. With this new approach, we achieve a translation performance comparable to the existing state-of-the-art phrase-based system on the task of English-to-French translation. Furthermore, qualitative analysis reveals that the (soft-)alignments found by the model agree well with our intuition.

### 1 INTRODUCTION

*Neural machine translation* is a newly emerging approach to machine translation, recently proposed by [Kalchbrenner and Blunsom](#page-10-0) [\(2013\)](#page-10-0), [Sutskever](#page-10-1) *et al.* [\(2014\)](#page-10-1) and Cho *[et al.](#page-9-0)* [\(2014b\)](#page-9-0). Unlike the traditional phrase-based translation system (see, e.g., [Koehn](#page-10-2) *et al.*, [2003\)](#page-10-2) which consists of many small sub-components that are tuned separately, neural machine translation attempts to build and train a single, large neural network that reads a sentence and outputs a correct translation.

Most of the proposed neural machine translation models belong to a family of *encoder– decoders* [\(Sutskever](#page-10-1) *et al.*, [2014;](#page-10-1) Cho *[et al.](#page-9-1)*, [2014a\)](#page-9-1), with an encoder and a decoder for each language, or involve a language-specific encoder applied to each sentence whose outputs are then compared [\(Hermann and Blunsom, 2014\)](#page-10-3). An encoder neural network reads and encodes a source sentence into a fixed-length vector. A decoder then outputs a translation from the encoded vector. The whole encoder–decoder system, which consists of the encoder and the decoder for a language pair, is jointly trained to maximize the probability of a correct translation given a source sentence.

A potential issue with this encoder–decoder approach is that a neural network needs to be able to compress all the necessary information of a source sentence into a fixed-length vector. This may make it difficult for the neural network to cope with long sentences, especially those that are longer than the sentences in the training corpus. Cho *[et al.](#page-9-0)* [\(2014b\)](#page-9-0) showed that indeed the performance of a basic encoder–decoder deteriorates rapidly as the length of an input sentence increases.

In order to address this issue, we introduce an extension to the encoder–decoder model which learns to align and translate jointly. Each time the proposed model generates a word in a translation, it (soft-)searches for a set of positions in a source sentence where the most relevant information is concentrated. The model then predicts a target word based on the context vectors associated with these source positions and all the previous generated target words.

<sup>∗</sup>CIFAR Senior Fellow

The most important distinguishing feature of this approach from the basic encoder–decoder is that it does not attempt to encode a whole input sentence into a single fixed-length vector. Instead, it encodes the input sentence into a sequence of vectors and chooses a subset of these vectors adaptively while decoding the translation. This frees a neural translation model from having to squash all the information of a source sentence, regardless of its length, into a fixed-length vector. We show this allows a model to cope better with long sentences.

In this paper, we show that the proposed approach of jointly learning to align and translate achieves significantly improved translation performance over the basic encoder–decoder approach. The improvement is more apparent with longer sentences, but can be observed with sentences of any length. On the task of English-to-French translation, the proposed approach achieves, with a single model, a translation performance comparable, or close, to the conventional phrase-based system. Furthermore, qualitative analysis reveals that the proposed model finds a linguistically plausible (soft-)alignment between a source sentence and the corresponding target sentence.

### 2 BACKGROUND: NEURAL MACHINE TRANSLATION

From a probabilistic perspective, translation is equivalent to finding a target sentence y that maximizes the conditional probability of y given a source sentence x, i.e., arg max<sup>y</sup> p(y | x). In neural machine translation, we fit a parameterized model to maximize the conditional probability of sentence pairs using a parallel training corpus. Once the conditional distribution is learned by a translation model, given a source sentence a corresponding translation can be generated by searching for the sentence that maximizes the conditional probability.

Recently, a number of papers have proposed the use of neural networks to directly learn this conditional distribution (see, e.g., [Kalchbrenner and Blunsom, 2013;](#page-10-0) Cho *[et al.](#page-9-1)*, [2014a;](#page-9-1) [Sutskever](#page-10-1) *et al.*, [2014;](#page-10-1) Cho *[et al.](#page-9-0)*, [2014b;](#page-9-0) [Forcada and](#page-9-2) Neco, [1997\)](#page-9-2). This neural machine translation approach typ- ˜ ically consists of two components, the first of which encodes a source sentence x and the second decodes to a target sentence y. For instance, two recurrent neural networks (RNN) were used by (Cho *[et al.](#page-9-1)*, [2014a\)](#page-9-1) and [\(Sutskever](#page-10-1) *et al.*, [2014\)](#page-10-1) to encode a variable-length source sentence into a fixed-length vector and to decode the vector into a variable-length target sentence.

Despite being a quite new approach, neural machine translation has already shown promising results. [Sutskever](#page-10-1) *et al.* [\(2014\)](#page-10-1) reported that the neural machine translation based on RNNs with long shortterm memory (LSTM) units achieves close to the state-of-the-art performance of the conventional phrase-based machine translation system on an English-to-French translation task.[1](#page-1-0) Adding neural components to existing translation systems, for instance, to score the phrase pairs in the phrase table (Cho *[et al.](#page-9-1)*, [2014a\)](#page-9-1) or to re-rank candidate translations [\(Sutskever](#page-10-1) *et al.*, [2014\)](#page-10-1), has allowed to surpass the previous state-of-the-art performance level.

#### 2.1 RNN ENCODER–DECODER

Here, we describe briefly the underlying framework, called *RNN Encoder–Decoder*, proposed by Cho *[et al.](#page-9-1)* [\(2014a\)](#page-9-1) and [Sutskever](#page-10-1) *et al.* [\(2014\)](#page-10-1) upon which we build a novel architecture that learns to align and translate simultaneously.

In the Encoder–Decoder framework, an encoder reads the input sentence, a sequence of vectors x = (x1, · · · , x<sup>T</sup><sup>x</sup> ), into a vector c. [2](#page-1-1) The most common approach is to use an RNN such that

<span id="page-1-2"></span>
$$h\_t = f\left(x\_t, h\_{t-1}\right) \tag{l}$$

and

$$c = q\left(\{h\_1, \dots, h\_{T\_x}\}\right),$$

where h<sup>t</sup> ∈ R <sup>n</sup> is a hidden state at time t, and c is a vector generated from the sequence of the hidden states. f and q are some nonlinear functions. [Sutskever](#page-10-1) *et al.* [\(2014\)](#page-10-1) used an LSTM as f and q ({h1, · · · , h<sup>T</sup> }) = h<sup>T</sup> , for instance.

<span id="page-1-0"></span><sup>1</sup> We mean by the state-of-the-art performance, the performance of the conventional phrase-based system without using any neural network-based component.

<span id="page-1-1"></span><sup>2</sup> Although most of the previous works (see, e.g., Cho *[et al.](#page-9-1)*, [2014a;](#page-9-1) [Sutskever](#page-10-1) *et al.*, [2014;](#page-10-1) [Kalchbrenner and](#page-10-0) [Blunsom, 2013\)](#page-10-0) used to encode a variable-length input sentence into a *fixed-length* vector, it is not necessary, and even it may be beneficial to have a *variable-length* vector, as we will show later.

The decoder is often trained to predict the next word y<sup>t</sup> <sup>0</sup> given the context vector c and all the previously predicted words {y1, · · · , y<sup>t</sup> <sup>0</sup>−1}. In other words, the decoder defines a probability over the translation y by decomposing the joint probability into the ordered conditionals:

$$p(\mathbf{y}) = \prod\_{t=1}^{T} p(y\_t \mid \{y\_1, \dots, y\_{t-1}\}, c), \tag{2}$$

where y = y1, · · · , yT<sup>y</sup> . With an RNN, each conditional probability is modeled as

$$p(y\_t \mid \{y\_1, \dots, y\_{t-1}\}, c) = g(y\_{t-1}, s\_t, c), \tag{3}$$

where g is a nonlinear, potentially multi-layered, function that outputs the probability of yt, and s<sup>t</sup> is the hidden state of the RNN. It should be noted that other architectures such as a hybrid of an RNN and a de-convolutional neural network can be used [\(Kalchbrenner and Blunsom, 2013\)](#page-10-0).

### <span id="page-2-6"></span>3 LEARNING TO ALIGN AND TRANSLATE

In this section, we propose a novel architecture for neural machine translation. The new architecture consists of a bidirectional RNN as an encoder (Sec. [3.2\)](#page-3-0) and a decoder that emulates searching through a source sentence during decoding a translation (Sec. [3.1\)](#page-2-0).

#### <span id="page-2-0"></span>3.1 DECODER: GENERAL DESCRIPTION

In a new model architecture, we define each conditional probability in Eq. [\(2\)](#page-2-1) as:

$$p(y\_i|y\_1, \ldots, y\_{i-1}, \mathbf{x}) = g(y\_{i-1}, s\_i, c\_i), \tag{4}$$

where s<sup>i</sup> is an RNN hidden state for time i, computed by

$$s\_i = f(s\_{i-1}, y\_{i-1}, c\_i).$$

It should be noted that unlike the existing encoder–decoder approach (see Eq. [\(2\)](#page-2-1)), here the probability is conditioned on a distinct context vector c<sup>i</sup> for each target word y<sup>i</sup> .

The context vector c<sup>i</sup> depends on a sequence of *annotations* (h1, · · · , hT<sup>x</sup> ) to which an encoder maps the input sentence. Each annotation h<sup>i</sup> contains information about the whole input sequence with a strong focus on the parts surrounding the i-th word of the input sequence. We explain in detail how the annotations are computed in the next section.

The context vector c<sup>i</sup> is, then, computed as a weighted sum of these annotations h<sup>i</sup> :

$$c\_i = \sum\_{j=1}^{T\_x} \alpha\_{ij} h\_j. \tag{5}$$

The weight αij of each annotation h<sup>j</sup> is computed by

$$\alpha\_{ij} = \frac{\exp\left(e\_{ij}\right)}{\sum\_{k=1}^{T\_x} \exp\left(e\_{ik}\right)},\tag{6}$$

where

$$e\_{ij} = a(s\_{i-1}, h\_j).$$

is an *alignment model* which scores how well the inputs around position j and the output at position i match. The score is based on the RNN hidden state si−<sup>1</sup> (just before emitting y<sup>i</sup> , Eq. [\(4\)](#page-2-2)) and the j-th annotation h<sup>j</sup> of the input sentence.

We parametrize the alignment model a as a feedforward neural network which is jointly trained with all the other components of the proposed system. Note that unlike in traditional machine translation,

<span id="page-2-2"></span><span id="page-2-1"></span>![](_page_2_Figure_23.jpeg)

<span id="page-2-5"></span><span id="page-2-4"></span><span id="page-2-3"></span>Figure 1: The graphical illustration of the proposed model trying to generate the t-th target word y<sup>t</sup> given a source sentence (x1, x2, . . . , x<sup>T</sup> ).

the alignment is not considered to be a latent variable. Instead, the alignment model directly computes a soft alignment, which allows the gradient of the cost function to be backpropagated through. This gradient can be used to train the alignment model as well as the whole translation model jointly.

We can understand the approach of taking a weighted sum of all the annotations as computing an *expected annotation*, where the expectation is over possible alignments. Let αij be a probability that the target word y<sup>i</sup> is aligned to, or translated from, a source word x<sup>j</sup> . Then, the i-th context vector ci is the expected annotation over all the annotations with probabilities αij .

The probability αij , or its associated energy eij , reflects the importance of the annotation h<sup>j</sup> with respect to the previous hidden state si−<sup>1</sup> in deciding the next state s<sup>i</sup> and generating y<sup>i</sup> . Intuitively, this implements a mechanism of attention in the decoder. The decoder decides parts of the source sentence to pay attention to. By letting the decoder have an attention mechanism, we relieve the encoder from the burden of having to encode all information in the source sentence into a fixedlength vector. With this new approach the information can be spread throughout the sequence of annotations, which can be selectively retrieved by the decoder accordingly.

### <span id="page-3-0"></span>3.2 ENCODER: BIDIRECTIONAL RNN FOR ANNOTATING SEQUENCES

The usual RNN, described in Eq. [\(1\)](#page-1-2), reads an input sequence x in order starting from the first symbol x<sup>1</sup> to the last one xT<sup>x</sup> . However, in the proposed scheme, we would like the annotation of each word to summarize not only the preceding words, but also the following words. Hence, we propose to use a bidirectional RNN (BiRNN, [Schuster and Paliwal, 1997\)](#page-10-4), which has been successfully used recently in speech recognition (see, e.g., [Graves](#page-9-3) *et al.*, [2013\)](#page-9-3).

A BiRNN consists of forward and backward RNN's. The forward RNN −→<sup>f</sup> reads the input sequence as it is ordered (from x<sup>1</sup> to xT<sup>x</sup> ) and calculates a sequence of *forward hidden states* ( −→<sup>h</sup> <sup>1</sup>, · · · , −→<sup>h</sup> <sup>T</sup><sup>x</sup> ). The backward RNN ←−<sup>f</sup> reads the sequence in the reverse order (from <sup>x</sup>T<sup>x</sup> to x1), resulting in a sequence of *backward hidden states* ( ←− h <sup>1</sup>, · · · , ←− h <sup>T</sup><sup>x</sup> ).

We obtain an annotation for each word x<sup>j</sup> by concatenating the forward hidden state −→<sup>h</sup> <sup>j</sup> and the backward one ←− h <sup>j</sup> , i.e., h<sup>j</sup> = h−→h > j ; ←− h > j i> . In this way, the annotation h<sup>j</sup> contains the summaries of both the preceding words and the following words. Due to the tendency of RNNs to better represent recent inputs, the annotation h<sup>j</sup> will be focused on the words around x<sup>j</sup> . This sequence of annotations is used by the decoder and the alignment model later to compute the context vector (Eqs. [\(5\)](#page-2-3)–[\(6\)](#page-2-4)).

See Fig. [1](#page-2-5) for the graphical illustration of the proposed model.

# <span id="page-3-4"></span>4 EXPERIMENT SETTINGS

We evaluate the proposed approach on the task of English-to-French translation. We use the bilingual, parallel corpora provided by ACL WMT '14.[3](#page-3-1) As a comparison, we also report the performance of an RNN Encoder–Decoder which was proposed recently by Cho *[et al.](#page-9-1)* [\(2014a\)](#page-9-1). We use the same training procedures and the same dataset for both models.[4](#page-3-2)

### 4.1 DATASET

WMT '14 contains the following English-French parallel corpora: Europarl (61M words), news commentary (5.5M), UN (421M) and two crawled corpora of 90M and 272.5M words respectively, totaling 850M words. Following the procedure described in Cho *[et al.](#page-9-1)* [\(2014a\)](#page-9-1), we reduce the size of the combined corpus to have 348M words using the data selection method by [Axelrod](#page-9-4) *et al.* [\(2011\)](#page-9-4).[5](#page-3-3) We do not use any monolingual data other than the mentioned parallel corpora, although it may be possible to use a much larger monolingual corpus to pretrain an encoder. We concatenate news-test-

<span id="page-3-1"></span><sup>3</sup> <http://www.statmt.org/wmt14/translation-task.html>

<span id="page-3-2"></span><sup>4</sup> Implementations are available at <https://github.com/lisa-groundhog/GroundHog>.

<span id="page-3-3"></span><sup>5</sup> Available online at [http://www-lium.univ-lemans.fr/˜schwenk/cslm\\_joint\\_paper/](http://www-lium.univ-lemans.fr/~schwenk/cslm_joint_paper/).

![](_page_4_Figure_1.jpeg)

<span id="page-4-2"></span>Figure 2: The BLEU scores of the generated translations on the test set with respect to the lengths of the sentences. The results are on the full test set which includes sentences having unknown words to the models.

2012 and news-test-2013 to make a development (validation) set, and evaluate the models on the test set (news-test-2014) from WMT '14, which consists of 3003 sentences not present in the training data.

After a usual tokenization[6](#page-4-0) , we use a shortlist of 30,000 most frequent words in each language to train our models. Any word not included in the shortlist is mapped to a special token ([UNK]). We do not apply any other special preprocessing, such as lowercasing or stemming, to the data.

#### 4.2 MODELS

We train two types of models. The first one is an RNN Encoder–Decoder (RNNencdec, Cho *[et al.](#page-9-1)*, [2014a\)](#page-9-1), and the other is the proposed model, to which we refer as RNNsearch. We train each model twice: first with the sentences of length up to 30 words (RNNencdec-30, RNNsearch-30) and then with the sentences of length up to 50 word (RNNencdec-50, RNNsearch-50).

The encoder and decoder of the RNNencdec have 1000 hidden units each.[7](#page-4-1) The encoder of the RNNsearch consists of forward and backward recurrent neural networks (RNN) each having 1000 hidden units. Its decoder has 1000 hidden units. In both cases, we use a multilayer network with a single maxout [\(Goodfellow](#page-9-5) *et al.*, [2013\)](#page-9-5) hidden layer to compute the conditional probability of each target word [\(Pascanu](#page-10-5) *et al.*, [2014\)](#page-10-5).

We use a minibatch stochastic gradient descent (SGD) algorithm together with Adadelta [\(Zeiler,](#page-10-6) [2012\)](#page-10-6) to train each model. Each SGD update direction is computed using a minibatch of 80 sentences. We trained each model for approximately 5 days.

Once a model is trained, we use a beam search to find a translation that approximately maximizes the conditional probability (see, e.g., [Graves, 2012;](#page-9-6) [Boulanger-Lewandowski](#page-9-7) *et al.*, [2013\)](#page-9-7). [Sutskever](#page-10-1) *[et al.](#page-10-1)* [\(2014\)](#page-10-1) used this approach to generate translations from their neural machine translation model.

For more details on the architectures of the models and training procedure used in the experiments, see Appendices [A](#page-11-0) and [B.](#page-13-0)

# <span id="page-4-3"></span>5 RESULTS

### 5.1 QUANTITATIVE RESULTS

In Table [1,](#page-6-0) we list the translation performances measured in BLEU score. It is clear from the table that in all the cases, the proposed RNNsearch outperforms the conventional RNNencdec. More importantly, the performance of the RNNsearch is as high as that of the conventional phrase-based translation system (Moses), when only the sentences consisting of known words are considered. This is a significant achievement, considering that Moses uses a separate monolingual corpus (418M words) in addition to the parallel corpora we used to train the RNNsearch and RNNencdec.

<span id="page-4-0"></span><sup>6</sup> We used the tokenization script from the open-source machine translation package, Moses.

<span id="page-4-1"></span><sup>7</sup> In this paper, by a 'hidden unit', we always mean the gated hidden unit (see Appendix [A.1.1\)](#page-11-1).

![](_page_5_Figure_1.jpeg)

<span id="page-5-0"></span>Figure 3: Four sample alignments found by RNNsearch-50. The x-axis and y-axis of each plot correspond to the words in the source sentence (English) and the generated translation (French), respectively. Each pixel shows the weight αij of the annotation of the j-th source word for the i-th target word (see Eq. [\(6\)](#page-2-4)), in grayscale (0: black, 1: white). (a) an arbitrary sentence. (b–d) three randomly selected samples among the sentences without any unknown words and of length between 10 and 20 words from the test set.

One of the motivations behind the proposed approach was the use of a fixed-length context vector in the basic encoder–decoder approach. We conjectured that this limitation may make the basic encoder–decoder approach to underperform with long sentences. In Fig. [2,](#page-4-2) we see that the performance of RNNencdec dramatically drops as the length of the sentences increases. On the other hand, both RNNsearch-30 and RNNsearch-50 are more robust to the length of the sentences. RNNsearch-50, especially, shows no performance deterioration even with sentences of length 50 or more. This superiority of the proposed model over the basic encoder–decoder is further confirmed by the fact that the RNNsearch-30 even outperforms RNNencdec-50 (see Table [1\)](#page-6-0).

| All   | No UNK◦ |
|-------|---------|
|       | 24.19   |
| 21.50 | 31.44   |
| 17.82 | 26.71   |
| 26.75 | 34.16   |
| 28.45 | 36.15   |
| 33.30 | 35.63   |
|       | 13.93   |

<span id="page-6-0"></span>Table 1: BLEU scores of the trained models computed on the test set. The second and third columns show respectively the scores on all the sentences and, on the sentences without any unknown word in themselves and in the reference translations. Note that RNNsearch-50? was trained much longer until the performance on the development set stopped improving. (◦) We disallowed the models to generate [UNK] tokens when only the sentences having no unknown words were evaluated (last column).

#### 5.2 QUALITATIVE ANALYSIS

#### 5.2.1 ALIGNMENT

The proposed approach provides an intuitive way to inspect the (soft-)alignment between the words in a generated translation and those in a source sentence. This is done by visualizing the annotation weights αij from Eq. [\(6\)](#page-2-4), as in Fig. [3.](#page-5-0) Each row of a matrix in each plot indicates the weights associated with the annotations. From this we see which positions in the source sentence were considered more important when generating the target word.

We can see from the alignments in Fig. [3](#page-5-0) that the alignment of words between English and French is largely monotonic. We see strong weights along the diagonal of each matrix. However, we also observe a number of non-trivial, non-monotonic alignments. Adjectives and nouns are typically ordered differently between French and English, and we see an example in Fig. [3](#page-5-0) (a). From this figure, we see that the model correctly translates a phrase [European Economic Area] into [zone economique europ ´ een]. The RNNsearch was able to correctly align [zone] with [Area], jumping ´ over the two words ([European] and [Economic]), and then looked one word back at a time to complete the whole phrase [zone economique europ ´ eenne]. ´

The strength of the soft-alignment, opposed to a hard-alignment, is evident, for instance, from Fig. [3](#page-5-0) (d). Consider the source phrase [the man] which was translated into [l' homme]. Any hard alignment will map [the] to [l'] and [man] to [homme]. This is not helpful for translation, as one must consider the word following [the] to determine whether it should be translated into [le], [la], [les] or [l']. Our soft-alignment solves this issue naturally by letting the model look at both [the] and [man], and in this example, we see that the model was able to correctly translate [the] into [l']. We observe similar behaviors in all the presented cases in Fig. [3.](#page-5-0) An additional benefit of the soft alignment is that it naturally deals with source and target phrases of different lengths, without requiring a counter-intuitive way of mapping some words to or from nowhere ([NULL]) (see, e.g., Chapters 4 and 5 of [Koehn, 2010\)](#page-10-7).

#### 5.2.2 LONG SENTENCES

As clearly visible from Fig. [2](#page-4-2) the proposed model (RNNsearch) is much better than the conventional model (RNNencdec) at translating long sentences. This is likely due to the fact that the RNNsearch does not require encoding a long sentence into a fixed-length vector perfectly, but only accurately encoding the parts of the input sentence that surround a particular word.

As an example, consider this source sentence from the test set:

*An admitting privilege is the right of a doctor to admit a patient to a hospital or a medical centre to carry out a diagnosis or a procedure, based on his status as a health care worker at a hospital.*

The RNNencdec-50 translated this sentence into:

*Un privilege d'admission est le droit d'un m ` edecin de reconna ´ ˆıtre un patient a` l'hopital ou un centre m ˆ edical ´ d'un diagnostic ou de prendre un diagnostic en fonction de son etat ´ de sante.´*

The RNNencdec-50 correctly translated the source sentence until [a medical center]. However, from there on (underlined), it deviated from the original meaning of the source sentence. For instance, it replaced [based on his status as a health care worker at a hospital] in the source sentence with [en fonction de son etat de sant ´ e] ("based on his state of health"). ´

On the other hand, the RNNsearch-50 generated the following correct translation, preserving the whole meaning of the input sentence without omitting any details:

*Un privilege d'admission est le droit d'un m ` edecin d'admettre un patient ´ a un ` hopital ou un centre m ˆ edical ´ pour effectuer un diagnostic ou une procedure, ´ selon son statut de travailleur des soins de sante´ a` l'hopital. ˆ*

Let us consider another sentence from the test set:

*This kind of experience is part of Disney's efforts to "extend the lifetime of its series and build new relationships with audiences via digital platforms that are becoming ever more important," he added.*

The translation by the RNNencdec-50 is

*Ce type d'experience fait partie des initiatives du Disney pour "prolonger la dur ´ ee´ de vie de ses nouvelles et de developper des liens avec les ´ lecteurs numeriques ´ qui deviennent plus complexes.*

As with the previous example, the RNNencdec began deviating from the actual meaning of the source sentence after generating approximately 30 words (see the underlined phrase). After that point, the quality of the translation deteriorates, with basic mistakes such as the lack of a closing quotation mark.

Again, the RNNsearch-50 was able to translate this long sentence correctly:

*Ce genre d'experience fait partie des efforts de Disney pour "prolonger la dur ´ ee´ de vie de ses series et cr ´ eer de nouvelles relations avec des publics ´ via des plateformes numeriques ´ de plus en plus importantes", a-t-il ajoute.´*

In conjunction with the quantitative results presented already, these qualitative observations confirm our hypotheses that the RNNsearch architecture enables far more reliable translation of long sentences than the standard RNNencdec model.

In Appendix [C,](#page-14-0) we provide a few more sample translations of long source sentences generated by the RNNencdec-50, RNNsearch-50 and Google Translate along with the reference translations.

### 6 RELATED WORK

#### 6.1 LEARNING TO ALIGN

A similar approach of aligning an output symbol with an input symbol was proposed recently by [Graves](#page-9-8) [\(2013\)](#page-9-8) in the context of handwriting synthesis. Handwriting synthesis is a task where the model is asked to generate handwriting of a given sequence of characters. In his work, he used a mixture of Gaussian kernels to compute the weights of the annotations, where the location, width and mixture coefficient of each kernel was predicted from an alignment model. More specifically, his alignment was restricted to predict the location such that the location increases monotonically.

The main difference from our approach is that, in [\(Graves, 2013\)](#page-9-8), the modes of the weights of the annotations only move in one direction. In the context of machine translation, this is a severe limitation, as (long-distance) reordering is often needed to generate a grammatically correct translation (for instance, English-to-German).

Our approach, on the other hand, requires computing the annotation weight of every word in the source sentence for each word in the translation. This drawback is not severe with the task of translation in which most of input and output sentences are only 15–40 words. However, this may limit the applicability of the proposed scheme to other tasks.

### 6.2 NEURAL NETWORKS FOR MACHINE TRANSLATION

Since [Bengio](#page-9-9) *et al.* [\(2003\)](#page-9-9) introduced a neural probabilistic language model which uses a neural network to model the conditional probability of a word given a fixed number of the preceding words, neural networks have widely been used in machine translation. However, the role of neural networks has been largely limited to simply providing a single feature to an existing statistical machine translation system or to re-rank a list of candidate translations provided by an existing system.

For instance, [Schwenk](#page-10-8) [\(2012\)](#page-10-8) proposed using a feedforward neural network to compute the score of a pair of source and target phrases and to use the score as an additional feature in the phrase-based statistical machine translation system. More recently, [Kalchbrenner and Blunsom](#page-10-0) [\(2013\)](#page-10-0) and [Devlin](#page-9-10) *[et al.](#page-9-10)* [\(2014\)](#page-9-10) reported the successful use of the neural networks as a sub-component of the existing translation system. Traditionally, a neural network trained as a target-side language model has been used to rescore or rerank a list of candidate translations (see, e.g., [Schwenk](#page-10-9) *et al.*, [2006\)](#page-10-9).

Although the above approaches were shown to improve the translation performance over the stateof-the-art machine translation systems, we are more interested in a more ambitious objective of designing a completely new translation system based on neural networks. The neural machine translation approach we consider in this paper is therefore a radical departure from these earlier works. Rather than using a neural network as a part of the existing system, our model works on its own and generates a translation from a source sentence directly.

# 7 CONCLUSION

The conventional approach to neural machine translation, called an encoder–decoder approach, encodes a whole input sentence into a fixed-length vector from which a translation will be decoded. We conjectured that the use of a fixed-length context vector is problematic for translating long sentences, based on a recent empirical study reported by Cho *[et al.](#page-9-0)* [\(2014b\)](#page-9-0) and [Pouget-Abadie](#page-10-10) *et al.* [\(2014\)](#page-10-10).

In this paper, we proposed a novel architecture that addresses this issue. We extended the basic encoder–decoder by letting a model (soft-)search for a set of input words, or their annotations computed by an encoder, when generating each target word. This frees the model from having to encode a whole source sentence into a fixed-length vector, and also lets the model focus only on information relevant to the generation of the next target word. This has a major positive impact on the ability of the neural machine translation system to yield good results on longer sentences. Unlike with the traditional machine translation systems, all of the pieces of the translation system, including the alignment mechanism, are jointly trained towards a better log-probability of producing correct translations.

We tested the proposed model, called RNNsearch, on the task of English-to-French translation. The experiment revealed that the proposed RNNsearch outperforms the conventional encoder–decoder model (RNNencdec) significantly, regardless of the sentence length and that it is much more robust to the length of a source sentence. From the qualitative analysis where we investigated the (soft-)alignment generated by the RNNsearch, we were able to conclude that the model can correctly align each target word with the relevant words, or their annotations, in the source sentence as it generated a correct translation.

Perhaps more importantly, the proposed approach achieved a translation performance comparable to the existing phrase-based statistical machine translation. It is a striking result, considering that the proposed architecture, or the whole family of neural machine translation, has only been proposed as recently as this year. We believe the architecture proposed here is a promising step toward better machine translation and a better understanding of natural languages in general.

One of challenges left for the future is to better handle unknown, or rare words. This will be required for the model to be more widely used and to match the performance of current state-of-the-art machine translation systems in all contexts.

### ACKNOWLEDGMENTS

The authors would like to thank the developers of Theano [\(Bergstra](#page-9-11) *et al.*, [2010;](#page-9-11) [Bastien](#page-9-12) *et al.*, [2012\)](#page-9-12). We acknowledge the support of the following agencies for research funding and computing support: NSERC, Calcul Quebec, Compute Canada, the Canada Research Chairs and CIFAR. Bah- ´ danau thanks the support from Planet Intelligent Systems GmbH. We also thank Felix Hill, Bart van Merrienboer, Jean Pouget-Abadie, Coline Devin and Tae-Ho Kim. ´

### REFERENCES

- <span id="page-9-4"></span>Axelrod, A., He, X., and Gao, J. (2011). Domain adaptation via pseudo in-domain data selection. In *Proceedings of the ACL Conference on Empirical Methods in Natural Language Processing (EMNLP)*, pages 355–362. Association for Computational Linguistics.
- <span id="page-9-12"></span>Bastien, F., Lamblin, P., Pascanu, R., Bergstra, J., Goodfellow, I. J., Bergeron, A., Bouchard, N., and Bengio, Y. (2012). Theano: new features and speed improvements. Deep Learning and Unsupervised Feature Learning NIPS 2012 Workshop.
- <span id="page-9-13"></span>Bengio, Y., Simard, P., and Frasconi, P. (1994). Learning long-term dependencies with gradient descent is difficult. *IEEE Transactions on Neural Networks*, 5(2), 157–166.
- <span id="page-9-9"></span>Bengio, Y., Ducharme, R., Vincent, P., and Janvin, C. (2003). A neural probabilistic language model. *J. Mach. Learn. Res.*, 3, 1137–1155.
- <span id="page-9-11"></span>Bergstra, J., Breuleux, O., Bastien, F., Lamblin, P., Pascanu, R., Desjardins, G., Turian, J., Warde-Farley, D., and Bengio, Y. (2010). Theano: a CPU and GPU math expression compiler. In *Proceedings of the Python for Scientific Computing Conference (SciPy)*. Oral Presentation.
- <span id="page-9-7"></span>Boulanger-Lewandowski, N., Bengio, Y., and Vincent, P. (2013). Audio chord recognition with recurrent neural networks. In *ISMIR*.
- <span id="page-9-1"></span>Cho, K., van Merrienboer, B., Gulcehre, C., Bougares, F., Schwenk, H., and Bengio, Y. (2014a). Learning phrase representations using RNN encoder-decoder for statistical machine translation. In *Proceedings of the Empiricial Methods in Natural Language Processing (EMNLP 2014)*. to appear.
- <span id="page-9-0"></span>Cho, K., van Merrienboer, B., Bahdanau, D., and Bengio, Y. (2014b). On the properties of neural ¨ machine translation: Encoder–Decoder approaches. In *Eighth Workshop on Syntax, Semantics and Structure in Statistical Translation*. to appear.
- <span id="page-9-10"></span>Devlin, J., Zbib, R., Huang, Z., Lamar, T., Schwartz, R., and Makhoul, J. (2014). Fast and robust neural network joint models for statistical machine translation. In *Association for Computational Linguistics*.
- <span id="page-9-2"></span>Forcada, M. L. and Neco, R. P. (1997). Recursive hetero-associative memories for translation. In ˜ J. Mira, R. Moreno-D´ıaz, and J. Cabestany, editors, *Biological and Artificial Computation: From Neuroscience to Technology*, volume 1240 of *Lecture Notes in Computer Science*, pages 453–462. Springer Berlin Heidelberg.
- <span id="page-9-5"></span>Goodfellow, I., Warde-Farley, D., Mirza, M., Courville, A., and Bengio, Y. (2013). Maxout networks. In *Proceedings of The 30th International Conference on Machine Learning*, pages 1319– 1327.
- <span id="page-9-6"></span>Graves, A. (2012). Sequence transduction with recurrent neural networks. In *Proceedings of the 29th International Conference on Machine Learning (ICML 2012)*.
- <span id="page-9-8"></span>Graves, A. (2013). Generating sequences with recurrent neural networks. *arXiv:*1308.0850 [cs.NE].
- <span id="page-9-3"></span>Graves, A., Jaitly, N., and Mohamed, A.-R. (2013). Hybrid speech recognition with deep bidirectional LSTM. In *Automatic Speech Recognition and Understanding (ASRU), 2013 IEEE Workshop on*, pages 273–278.
- <span id="page-10-3"></span>Hermann, K. and Blunsom, P. (2014). Multilingual distributed representations without word alignment. In *Proceedings of the Second International Conference on Learning Representations (ICLR 2014)*.
- <span id="page-10-12"></span>Hochreiter, S. (1991). Untersuchungen zu dynamischen neuronalen Netzen. Diploma thesis, Institut fur Informatik, Lehrstuhl Prof. Brauer, Technische Universit ¨ at M¨ unchen. ¨
- <span id="page-10-11"></span>Hochreiter, S. and Schmidhuber, J. (1997). Long short-term memory. *Neural Computation*, 9(8), 1735–1780.
- <span id="page-10-0"></span>Kalchbrenner, N. and Blunsom, P. (2013). Recurrent continuous translation models. In *Proceedings of the ACL Conference on Empirical Methods in Natural Language Processing (EMNLP)*, pages 1700–1709. Association for Computational Linguistics.
- <span id="page-10-7"></span>Koehn, P. (2010). *Statistical Machine Translation*. Cambridge University Press, New York, NY, USA.
- <span id="page-10-2"></span>Koehn, P., Och, F. J., and Marcu, D. (2003). Statistical phrase-based translation. In *Proceedings of the 2003 Conference of the North American Chapter of the Association for Computational Linguistics on Human Language Technology - Volume 1*, NAACL '03, pages 48–54, Stroudsburg, PA, USA. Association for Computational Linguistics.
- <span id="page-10-13"></span>Pascanu, R., Mikolov, T., and Bengio, Y. (2013a). On the difficulty of training recurrent neural networks. In *ICML'2013*.
- <span id="page-10-14"></span>Pascanu, R., Mikolov, T., and Bengio, Y. (2013b). On the difficulty of training recurrent neural networks. In *Proceedings of the 30th International Conference on Machine Learning (ICML 2013)*.
- <span id="page-10-5"></span>Pascanu, R., Gulcehre, C., Cho, K., and Bengio, Y. (2014). How to construct deep recurrent neural networks. In *Proceedings of the Second International Conference on Learning Representations (ICLR 2014)*.
- <span id="page-10-10"></span>Pouget-Abadie, J., Bahdanau, D., van Merrienboer, B., Cho, K., and Bengio, Y. (2014). Overcoming ¨ the curse of sentence length for neural machine translation using automatic segmentation. In *Eighth Workshop on Syntax, Semantics and Structure in Statistical Translation*. to appear.
- <span id="page-10-4"></span>Schuster, M. and Paliwal, K. K. (1997). Bidirectional recurrent neural networks. *Signal Processing, IEEE Transactions on*, 45(11), 2673–2681.
- <span id="page-10-8"></span>Schwenk, H. (2012). Continuous space translation models for phrase-based statistical machine translation. In M. Kay and C. Boitet, editors, *Proceedings of the 24th International Conference on Computational Linguistics (COLIN)*, pages 1071–1080. Indian Institute of Technology Bombay.
- <span id="page-10-9"></span>Schwenk, H., Dchelotte, D., and Gauvain, J.-L. (2006). Continuous space language models for statistical machine translation. In *Proceedings of the COLING/ACL on Main conference poster sessions*, pages 723–730. Association for Computational Linguistics.
- <span id="page-10-1"></span>Sutskever, I., Vinyals, O., and Le, Q. (2014). Sequence to sequence learning with neural networks. In *Advances in Neural Information Processing Systems (NIPS 2014)*.
- <span id="page-10-6"></span>Zeiler, M. D. (2012). ADADELTA: An adaptive learning rate method. *arXiv:*1212.5701 [cs.LG].

### <span id="page-11-0"></span>A MODEL ARCHITECTURE

#### A.1 ARCHITECTURAL CHOICES

The proposed scheme in Section [3](#page-2-6) is a general framework where one can freely define, for instance, the activation functions f of recurrent neural networks (RNN) and the alignment model a. Here, we describe the choices we made for the experiments in this paper.

#### <span id="page-11-1"></span>A.1.1 RECURRENT NEURAL NETWORK

For the activation function f of an RNN, we use the gated hidden unit recently proposed by [Cho](#page-9-1) *[et al.](#page-9-1)* [\(2014a\)](#page-9-1). The gated hidden unit is an alternative to the conventional *simple* units such as an element-wise tanh. This gated unit is similar to a long short-term memory (LSTM) unit proposed earlier by [Hochreiter and Schmidhuber](#page-10-11) [\(1997\)](#page-10-11), sharing with it the ability to better model and learn long-term dependencies. This is made possible by having computation paths in the unfolded RNN for which the product of derivatives is close to 1. These paths allow gradients to flow backward easily without suffering too much from the vanishing effect [\(Hochreiter, 1991;](#page-10-12) [Bengio](#page-9-13) *et al.*, [1994;](#page-9-13) [Pascanu](#page-10-13) *et al.*, [2013a\)](#page-10-13). It is therefore possible to use LSTM units instead of the gated hidden unit described here, as was done in a similar context by [Sutskever](#page-10-1) *et al.* [\(2014\)](#page-10-1).

The new state s<sup>i</sup> of the RNN employing n gated hidden units[8](#page-11-2) is computed by

$$s\_i = f(s\_{i-1}, y\_{i-1}, c\_i) = (1 - z\_i) \diamond s\_{i-1} + z\_i \diamond \tilde{s}\_i,$$

where ◦ is an element-wise multiplication, and z<sup>i</sup> is the output of the update gates (see below). The proposed updated state s˜<sup>i</sup> is computed by

$$
\tilde{s}\_i = \tanh\left(We(y\_{i-1}) + U\left[r\_i \circ s\_{i-1}\right] + Cc\_i\right),
$$

where e(yi−1) ∈ R <sup>m</sup> is an m-dimensional embedding of a word yi−1, and r<sup>i</sup> is the output of the reset gates (see below). When y<sup>i</sup> is represented as a 1-of-K vector, e(yi) is simply a column of an embedding matrix E ∈ R <sup>m</sup>×<sup>K</sup>. Whenever possible, we omit bias terms to make the equations less cluttered.

The update gates z<sup>i</sup> allow each hidden unit to maintain its previous activation, and the reset gates r<sup>i</sup> control how much and what information from the previous state should be reset. We compute them by

$$\begin{aligned} z\_i &= \sigma \left( W\_z e(y\_{i-1}) + U\_z s\_{i-1} + C\_z c\_i \right), \\ r\_i &= \sigma \left( W\_r e(y\_{i-1}) + U\_r s\_{i-1} + C\_r c\_i \right), \end{aligned}$$

where σ (·) is a logistic sigmoid function.

At each step of the decoder, we compute the output probability (Eq. [\(4\)](#page-2-2)) as a multi-layered function [\(Pascanu](#page-10-5) *et al.*, [2014\)](#page-10-5). We use a single hidden layer of maxout units [\(Goodfellow](#page-9-5) *et al.*, [2013\)](#page-9-5) and normalize the output probabilities (one for each word) with a softmax function (see Eq. [\(6\)](#page-2-4)).

#### A.1.2 ALIGNMENT MODEL

The alignment model should be designed considering that the model needs to be evaluated T<sup>x</sup> × T<sup>y</sup> times for each sentence pair of lengths T<sup>x</sup> and Ty. In order to reduce computation, we use a singlelayer multilayer perceptron such that

$$a(s\_{i-1}, h\_j) = v\_a^\top \tanh\left(W\_a s\_{i-1} + U\_a h\_j\right),$$

where W<sup>a</sup> ∈ R <sup>n</sup>×<sup>n</sup>, U<sup>a</sup> ∈ R <sup>n</sup>×2<sup>n</sup> and v<sup>a</sup> ∈ R <sup>n</sup> are the weight matrices. Since Uah<sup>j</sup> does not depend on i, we can pre-compute it in advance to minimize the computational cost.

<span id="page-11-2"></span><sup>8</sup> Here, we show the formula of the decoder. The same formula can be used in the encoder by simply ignoring the context vector c<sup>i</sup> and the related terms.

#### A.2 DETAILED DESCRIPTION OF THE MODEL

#### A.2.1 ENCODER

In this section, we describe in detail the architecture of the proposed model (RNNsearch) used in the experiments (see Sec. [4–](#page-3-4)[5\)](#page-4-3). From here on, we omit all bias terms in order to increase readability.

The model takes a source sentence of 1-of-K coded word vectors as input

$$\mathbf{x} = (x\_1, \dots, x\_{T\_x}), \ x\_i \in \mathbb{R}^{K\_{x\_i}}$$

and outputs a translated sentence of 1-of-K coded word vectors

$$\mathbf{y} = (y\_1, \dots, y\_{T\_y}), \ y\_i \in \mathbb{R}^{K\_y},$$

where K<sup>x</sup> and K<sup>y</sup> are the vocabulary sizes of source and target languages, respectively. T<sup>x</sup> and T<sup>y</sup> respectively denote the lengths of source and target sentences.

First, the forward states of the bidirectional recurrent neural network (BiRNN) are computed:

$$
\overrightarrow{\boldsymbol{h}}\_{i} = \begin{cases}
(1 - \overrightarrow{\boldsymbol{z}}\_{i}) \circ \overrightarrow{\boldsymbol{h}}\_{i-1} + \overrightarrow{\boldsymbol{z}}\_{i} \circ \overrightarrow{\underline{\boldsymbol{h}}}\_{i} & \text{, if } i > 0 \\
0 & \text{, if } i = 0
\end{cases}
$$

where

$$
\begin{split}
\overrightarrow{\underline{h}}\_{i} &= \tanh\left(\overrightarrow{W}\overrightarrow{E}x\_{i} + \overrightarrow{U}\left[\overrightarrow{r}\_{i}\circ\overrightarrow{h}\_{i-1}\right]\right), \\
\overrightarrow{\underline{z}}\_{i} &= \sigma\left(\overrightarrow{W}\_{z}\overrightarrow{E}x\_{i} + \overrightarrow{U}\_{z}\overset{\rightarrow}{h}\_{i-1}\right) \\
\overrightarrow{\overline{r}}\_{i} &= \sigma\left(\overrightarrow{W}\_{r}\overrightarrow{E}x\_{i} + \overrightarrow{U}\_{r}\overset{\rightarrow}{h}\_{i-1}\right).
\end{split}
$$

E ∈ R <sup>m</sup>×K<sup>x</sup> is the word embedding matrix. −→W , −→Wz, −→W<sup>r</sup> <sup>∈</sup> <sup>R</sup> <sup>n</sup>×<sup>m</sup>, −→U , −→U z, −→<sup>U</sup> <sup>r</sup> <sup>∈</sup> <sup>R</sup> <sup>n</sup>×<sup>n</sup> are weight matrices. m and n are the word embedding dimensionality and the number of hidden units, respectively. σ(·) is as usual a logistic sigmoid function.

The backward states ( ←− h <sup>1</sup>, · · · , ←− h <sup>T</sup><sup>x</sup> ) are computed similarly. We share the word embedding matrix E between the forward and backward RNNs, unlike the weight matrices.

We concatenate the forward and backward states to to obtain the annotations (h1, h2, · · · , hT<sup>x</sup> ), where

<span id="page-12-0"></span>
$$h\_i = \left[ \begin{array}{c} \overrightarrow{h}\_i \\ \overleftarrow{h}\_i \end{array} \right] \tag{7}$$

#### A.2.2 DECODER

The hidden state s<sup>i</sup> of the decoder given the annotations from the encoder is computed by

$$s\_i = (1 - z\_i) \diamond s\_{i-1} + z\_i \diamond \tilde{s}\_{i,i}$$

where

$$\begin{aligned} \tilde{s}\_i &= \tanh\left(WEy\_{i-1} + U\left[r\_i \circ s\_{i-1}\right] + Cc\_i\right) \\ z\_i &= \sigma\left(W\_zEy\_{i-1} + U\_zs\_{i-1} + C\_zc\_i\right) \\ r\_i &= \sigma\left(W\_rEy\_{i-1} + U\_rs\_{i-1} + C\_rc\_i\right) \end{aligned}$$

E is the word embedding matrix for the target language. W, Wz, W<sup>r</sup> ∈ R <sup>n</sup>×<sup>m</sup>, U, Uz, U<sup>r</sup> ∈ R <sup>n</sup>×<sup>n</sup>, and C, Cz, C<sup>r</sup> ∈ R <sup>n</sup>×2<sup>n</sup> are weights. Again, m and n are the word embedding dimensionality and the number of hidden units, respectively. The initial hidden state s<sup>0</sup> is computed by s<sup>0</sup> = tanh W<sup>s</sup> ←− h <sup>1</sup> , where W<sup>s</sup> ∈ R <sup>n</sup>×<sup>n</sup>.

The context vector c<sup>i</sup> are recomputed at each step by the alignment model:

$$c\_i = \sum\_{j=1}^{T\_x} \alpha\_{ij} h\_j,$$

| Model         | Updates (×105<br>) | Epochs | Hours | GPU           | Train NLL | Dev. NLL |
|---------------|--------------------|--------|-------|---------------|-----------|----------|
| RNNenc-30     | 8.46               | 6.4    | 109   | TITAN BLACK   | 28.1      | 53.0     |
| RNNenc-50     | 6.00               | 4.5    | 108   | Quadro K-6000 | 44.0      | 43.6     |
| RNNsearch-30  | 4.71               | 3.6    | 113   | TITAN BLACK   | 26.7      | 47.2     |
| RNNsearch-50  | 2.88               | 2.2    | 111   | Quadro K-6000 | 40.7      | 38.1     |
| RNNsearch-50? | 6.67               | 5.0    | 252   | Quadro K-6000 | 36.7      | 35.2     |

<span id="page-13-1"></span>Table 2: Learning statistics and relevant information. Each update corresponds to updating the parameters once using a single minibatch. One epoch is one pass through the training set. NLL is the average conditional log-probabilities of the sentences in either the training set or the development set. Note that the lengths of the sentences differ.

where

$$\begin{aligned} \alpha\_{ij} &= \frac{\exp\left(e\_{ij}\right)}{\sum\_{k=1}^{T\_x} \exp\left(e\_{ik}\right)}\\ e\_{ij} &= v\_a^\top \tanh\left(W\_a s\_{i-1} + U\_a h\_j\right), \end{aligned}$$

and h<sup>j</sup> is the j-th annotation in the source sentence (see Eq. [\(7\)](#page-12-0)). v<sup>a</sup> ∈ R n 0 , W<sup>a</sup> ∈ R n <sup>0</sup>×<sup>n</sup> and U<sup>a</sup> ∈ R n <sup>0</sup>×2<sup>n</sup> are weight matrices. Note that the model becomes RNN Encoder–Decoder [\(Cho](#page-9-1) *[et al.](#page-9-1)*, [2014a\)](#page-9-1), if we fix c<sup>i</sup> to −→<sup>h</sup> <sup>T</sup><sup>x</sup> .

With the decoder state si−1, the context c<sup>i</sup> and the last generated word yi−1, we define the probability of a target word y<sup>i</sup> as

$$p(y\_i|s\_i, y\_{i-1}, c\_i) \propto \exp\left(y\_i^\top W\_o t\_i\right),$$

where

$$t\_i = \left[ \max \left\{ \tilde{t}\_{i,2j-1}, \tilde{t}\_{i,2j} \right\} \right]\_{j=1,\ldots,l}^{\top}$$

and t˜i,k is the k-th element of a vector t˜<sup>i</sup> which is computed by

$$
\tilde{t}\_i = U\_o s\_{i-1} + V\_o E y\_{i-1} + C\_o c\_{i-1}
$$

W<sup>o</sup> ∈ R Ky×l , U<sup>o</sup> ∈ R <sup>2</sup>l×<sup>n</sup>, V<sup>o</sup> ∈ R <sup>2</sup>l×<sup>m</sup> and C<sup>o</sup> ∈ R <sup>2</sup>l×2<sup>n</sup> are weight matrices. This can be understood as having a deep output [\(Pascanu](#page-10-5) *et al.*, [2014\)](#page-10-5) with a single maxout hidden layer [\(Goodfellow](#page-9-5) *[et al.](#page-9-5)*, [2013\)](#page-9-5).

#### A.2.3 MODEL SIZE

For all the models used in this paper, the size of a hidden layer n is 1000, the word embedding dimensionality m is 620 and the size of the maxout hidden layer in the deep output l is 500. The number of hidden units in the alignment model n 0 is 1000.

### <span id="page-13-0"></span>B TRAINING PROCEDURE

#### B.1 PARAMETER INITIALIZATION

We initialized the recurrent weight matrices U, Uz, Ur, ←− U , ←− U <sup>z</sup>, ←− U <sup>r</sup>, −→U , −→<sup>U</sup> <sup>z</sup> and −→<sup>U</sup> <sup>r</sup> as random orthogonal matrices. For W<sup>a</sup> and Ua, we initialized them by sampling each element from the Gaussian distribution of mean 0 and variance 0.001<sup>2</sup> . All the elements of V<sup>a</sup> and all the bias vectors were initialized to zero. Any other weight matrix was initialized by sampling from the Gaussian distribution of mean 0 and variance 0.01<sup>2</sup> .

#### B.2 TRAINING

We used the stochastic gradient descent (SGD) algorithm. Adadelta [\(Zeiler, 2012\)](#page-10-6) was used to automatically adapt the learning rate of each parameter ( = 10<sup>−</sup><sup>6</sup> and ρ = 0.95). We explicitly normalized the L2-norm of the gradient of the cost function each time to be at most a predefined threshold of 1, when the norm was larger than the threshold [\(Pascanu](#page-10-14) *et al.*, [2013b\)](#page-10-14). Each SGD update direction was computed with a minibatch of 80 sentences.

At each update our implementation requires time proportional to the length of the longest sentence in a minibatch. Hence, to minimize the waste of computation, before every 20-th update, we retrieved 1600 sentence pairs, sorted them according to the lengths and split them into 20 minibatches. The training data was shuffled once before training and was traversed sequentially in this manner.

In Tables [2](#page-13-1) we present the statistics related to training all the models used in the experiments.

| Source              | An admitting privilege is the right of a doctor to admit a patient to a hospital or a medical centre<br>to carry out a diagnosis or a procedure, based on his status as a health care worker at a hospital.                                                                                                  |
|---------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Reference           | Le privilege d'admission est le droit d'un m<br>`<br>edecin, en vertu de son statut de membre soignant<br>´<br>d'un hopital, d'admettre un patient dans un h<br>ˆ<br>opital ou un centre m<br>ˆ<br>edical afin d'y d<br>´<br>elivrer un ´<br>diagnostic ou un traitement.                                    |
| RNNenc-50           | Un privilege d'admission est le droit d'un m<br>`<br>edecin de reconna<br>´<br>ˆıtre un patient a l'h ` opital ou un<br>ˆ<br>´<br>´<br>e.´<br>centre medical d'un diagnostic ou de prendre un diagnostic en fonction de son<br>etat de sant                                                                  |
| RNNsearch-50        | Un privilege d'admission est le droit d'un m<br>`<br>edecin d'admettre un patient<br>´<br>a un h ` opital ou un<br>ˆ<br>centre medical pour effectuer un diagnostic ou une proc<br>´<br>edure, selon son statut de travailleur des<br>´<br>soins de sante´ a l'h ` opital. ˆ                                 |
| Google<br>Translate | Un privilege admettre est le droit d'un m<br>`<br>edecin d'admettre un patient dans un h<br>´<br>opital ou un<br>ˆ<br>´<br>´<br>´<br>centre medical pour effectuer un diagnostic ou une proc<br>edure, fond<br>ee sur sa situation en tant<br>que travailleur de soins de sante dans un h<br>´<br>opital. ˆ  |
| Source              | This kind of experience is part of Disney's efforts to "extend the lifetime of its series and build<br>new relationships with audiences via digital platforms that are becoming ever more important,"<br>he added.                                                                                           |
| Reference           | Ce type d'experience entre dans le cadre des efforts de Disney pour "<br>´<br>etendre la dur<br>´<br>ee de ´<br>vie de ses series et construire de nouvelles relations avec son public gr<br>´<br>ace ˆ a des plateformes<br>`<br>numeriques qui sont de plus en plus importantes", a-t-il ajout<br>´<br>e.´ |
| RNNenc-50           | Ce type d'experience fait partie des initiatives du Disney pour "prolonger la dur<br>´<br>ee de vie de<br>´<br>ses nouvelles et de developper des liens avec les lecteurs num<br>´<br>eriques qui deviennent plus com-<br>´<br>plexes.                                                                       |
| RNNsearch-50        | Ce genre d'experience fait partie des efforts de Disney pour "prolonger la dur<br>´<br>ee de vie de ses<br>´<br>series et cr ´ eer de nouvelles relations avec des publics via des plateformes num<br>´<br>eriques de plus<br>´<br>en plus importantes", a-t-il ajoute.´                                     |
| Google<br>Translate | Ce genre d'experience fait partie des efforts de Disney<br>´<br>a " ` etendre la dur<br>´<br>ee de vie de sa s<br>´<br>erie et ´<br>construire de nouvelles relations avec le public par le biais des plates-formes numeriques qui<br>´<br>deviennent de plus en plus important", at-il ajoute.´             |
|                     |                                                                                                                                                                                                                                                                                                              |
| Source              | In a press conference on Thursday, Mr Blair stated that there was nothing in this video that might<br>constitute a "reasonable motive" that could lead to criminal charges being brought against the<br>mayor.                                                                                               |
| Reference           | En conference de presse, jeudi, M. Blair a affirm<br>´<br>e qu'il n'y avait rien dans cette vid<br>´<br>eo qui puisse<br>´<br>constituer des "motifs raisonnables" pouvant mener au dep´ ot d'une accusation criminelle contre<br>ˆ<br>le maire.                                                             |
| RNNenc-50           | Lors de la conference de presse de jeudi, M. Blair a dit qu'il n'y avait rien dans cette vid<br>´<br>eo qui ´<br>pourrait constituer une "motivation raisonnable" pouvant entraˆıner des accusations criminelles<br>portees contre le maire.<br>´                                                            |
| RNNsearch-50        | Lors d'une conference de presse jeudi, M. Blair a d<br>´<br>eclar ´ e qu'il n'y avait rien dans cette vid<br>´<br>eo qui ´<br>pourrait constituer un "motif raisonnable" qui pourrait conduire a des accusations criminelles<br>`<br>contre le maire.                                                        |
| Google<br>Translate | ´<br>eclar ´ e qu'il n'y avait rien dans cette vido<br>´<br>Lors d'une conference de presse jeudi, M. Blair a d<br>qui pourrait constituer un "motif raisonnable" qui pourrait mener a des accusations criminelles<br>`<br>portes contre le maire.                                                           |

# <span id="page-14-0"></span>C TRANSLATIONS OF LONG SENTENCES

Table 3: The translations generated by RNNenc-50 and RNNsearch-50 from long source sentences (30 words or more) selected from the test set. For each source sentence, we also show the goldstandard translation. The translations by Google Translate were made on 27 August 2014.