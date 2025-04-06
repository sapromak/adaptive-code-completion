### Questions that may appear

**Question:** Maybe the RoPE adjustment occurs faster than the adaptation to the new context composition strategy, causing the metric gains from the latter to appear only in the later repo-level pretraining phase. If this is the case, 1B tokens may not be sufficient to draw any conclusions. Do you have any longer runs to confirm that this is not the case?

**Answer:** Yes, we have a continuation of the Lines IoU .py composer for 3.8B tokens. Let's take a look at the W&B plots. EM: $49.3 \rightarrow 49.9$ of the cost of 2.8B additional tokens.
### Prompt for LLM

I am writing my presentation script. I have a very rough draft right now. Could you please help me refine it? You should:

1. Rephrase all constructions that contain errors.
2. Don't change the meaning, order, or content of the sentences unless otherwise stated.

I will paste the paragraphs or sections here and you will output your version. I will give my feedback and we will iteratively improve the text together.
### Script

<u>Slide #1</u>
#### Introduction

Hello, everyone! Today, I would like to share our results on the repository-level pretraining stage. This presentation is based on our Tiny Paper, which was accepted to ICLR this year. If you'd like to read it, here is a QR code, which will appear on the last slide as well. And a link in the Slack announcement message is also provided.

<u>Slide #2</u>
#### Code completion task

Let's start with the task specification, which forms the foundation of our study. For brevity, I will use the terms **code completion** and **full line code completion** interchangeably.

So, in this task our goal is to predict the end of a given line of code. Typically, this happens when a trigger model initiates a request while the user is typing the beginning of the line. Here we can see a completion file which consists of multiple lines of code, and we want to complete one of them.

<u>Slide #3</u>

So what we do is take our file, extract all the lines before our target line, and pass them to the language model that predicts the completion. Here we use any token that contains a newline character as an analog to the EOS token.

It is important to note that we do not consider the fill-in-the-middle (FIM) approach in our work. This means we do not provide a string followed by the completion line as part of the context.

<u>Slide #4</u>
#### Repository-level code completion task

Now let's refine our approach considering the broader context of the entire project. There are many ways to retrieve, preprocess, and assemble context for the model from the set of all repository files. Together, these operations define **context composition**. We call the function responsible for this process the **context composer**, or just **composer** for future reference. It produces a string which is then concatenated with the file prefix. Providing a larger context generally improves completion performance.

<u>Slide #5</u>
#### Training pipelines of Code LLMs

To describe our research focus, I first need to provide an overview of Code LLM pretraining pipelines. For the code completion task, instruction-following capabilities are not required. This means that the base model is sufficient, and we do not need to consider the Instruct version.

Code LLM training pipelines typically involve multiple stages. Some models (e.g., CodeLlama, Qwen2.5-Coder) begin with general-purpose pretrained LLMs and then refine them for a deeper understanding of code. Others are trained on code from scratch, often incorporating mixed natural language data (e.g., DeepSeek-Coder, OpenCoder). Both approaches require vast amounts of data, typically ranging from 2T to 18T tokens. It is common practice to use a context window size of 4K tokens during this phase.

Once a strong model with a limited context size is trained, it often undergoes repository-level pretraining. The goal of this stage is to extend the context window, enabling the model to comprehend a broader scope within a given repository.

Unlike the previous training stage, repository-level pretraining requires significantly fewer tokens. However, it necessitates the application of a context extrapolation method and, most importantly, the use of longer input sequences. This phase typically involves 8B to 300B training tokens, with the context window extended using 16K or 32K tokens.

Sometimes it can cause a problem with lack of resources. In our study, we show that this is not the only way to conduct a repository-level pretraining phase. There is a workaround that allows us to drastically reduce computations at the cost of a marginal decrease in target metrics.

<u>Slide #6</u>
#### Research question

We state the following research question: **"How does the choice of context composition strategy at the repository-level pretraining stage impact code completion performance?"**

<u>Slide #7</u>
#### Training

You can find details about the preprocessing steps for training data and hyperparameter choices in the paper. The resulting number of repository-level pretraining runs is 43. Now, I would like to move on to the evaluation part.
#### Evaluation

We use the **infile** and **inproject** categories from the Project-Level Code Completion task in the Long Code Arena benchmark to measure the model's adaptability to a new context window. They represent a completion line that contains an API declared in the completion file and in the repository snapshot file respectively.

The reported metric is Exact Match, which is the average number of correctly completed lines in the completion file.

<u>Slide #8</u>
#### Experiment design

Our experiment design consists of multiple fixed and varied parameters.

For each experiment, we use the OpenCoder 1.5B base model, which originally has a context size limitation of 4K tokens. We selected this model specifically because it did not undergo a repository-level pretraining stage. We then scale the RoPE base frequency from 10,000 to 500,000 and train the model with 1B tokens of curated repository-level data to extend its context with 16K token sequences. We maintain a consistent order of data samples and hyperparameters across all experiments.

We vary two parameters:
1. Choice of the context composer used in the repository-level pretraining stage,
2. Gradient masking.
##### Limitations and possible directions for exploration

Note that these choices imply the limitations of our work. The main limitation is the use of a single model — OpenCoder — making it unclear whether our results generalize to other LLMs. This limitation arises from the fact that recent Code LLMs were released after the repository-level pretraining stage.

Another aspect that we did not explore in our study is validating our results with different context extension methods, such as YaRN.

<u>Slide #9</u>
#### RoPE and theta scaling

Now, let me explain why the second point is relevant. Rotary Positional Embedding (or simply RoPE) is a widely used method for encoding the positional information of input tokens. It has several key properties:

-  It is applied in all attention layers, not just the first one, ensuring a uniform injection of positional information across the model's depth.
-  It does not introduce any positional noise into the token embedding stream.
-  It depends only on the relative distance $m - n$ between tokens.
-  And most importantly for our case, it exhibits strong interpolation but weak extrapolation capabilities.

This last point has a crucial implication for us. Since the model struggles with extrapolation, attempting to train it to overcome this limitation is not effective. Instead, we adjust a single parameter — called theta or base frequency — within RoPE. This adjustment shifts the model’s learning process into an interpolation-focused regime, where it performs better during and after additional training.

<u>Slide #10</u>
#### Composers

Some of our composers, when it makes sense, are presented with three different modes: original, reversed, and irrelevant. Here, you can see the differences between them. The selected mode determines the order in which the retrieved text chunks are concatenated. In most cases, each chunk corresponds to a single file in the repository.

<u>Slide #11</u>

We trained on a total of 15 different composers. We selected two of them as the convenient baselines:
-  File-level, which produces an empty string for the repo context.
-  Path distance .py, which takes only Python files from the repo and sorts them in descending order by their path distance from the completion file.

We also chose four context composition strategies for evaluation:
-  File-level with a maximum context length of 4K (FL-4K).
-  Repository files sorted in descending order by their path distance from the completion file, with both 4K and 16K (PD-16K) modes.
-  The original composition strategy used during repository-level pretraining with a 16K context length.

Given the two types of lines which were introduced earlier and these four evaluation composers, we have 8 different EM numbers to measure the performance of the checkpoint among its alternatives.

<u>Slide #12</u>
#### Complete uninterpreted results

Let's move on to the results. Of course, the paper contains a lot of numbers that you can explore in detail. To simplify all of this we have the following table.

<u>Slide #13</u>
#### Composer selection results

_Describe the table._

Here I have to say that we consider two sources of metric gains that the model can benefit from during repository-level pretraining:  
1. The first one is the adaptation to the new RoPE base frequency.
2. And the second is the adaptation to the new context composition strategy. This includes learning the new long sequence data format and gaining capabilities that are not needed in a file-level pretraining setup. For example, the model may begin to understand the cross-file dependencies.

Our results regarding the choice of a composition strategy are as follows:
-  The context composition strategy for the repository-level pretraining stage has a marginal impact on the final model's quality.
-  File-level training remains highly competitive, even without any repository context. Therefore, one can drastically reduce computations while still achieving fair results at the repository-level pretraining stage.
-  RoPE adjustment is the primary driver of long-context improvements.

<u>Slide #14</u>
#### Comparison with other Code LLMs

Here, you can see a comparison of our two main outlined checkpoints with other Code LLMs. A table version of this bar chart is available in the paper.

The composer used during the repository-level pretraining stage is shown in the chart's legend. An untouched version of OpenCoder is also evaluated. Each group of bars represents a different evaluation setup.

The competitive performance among strong models supports the claims made in the previous slide. We see how easy it is to avoid the difficulties of repository-level pretraining.

<u>Slide #15</u>
#### Performance scaling beyond training context window

Another outcome of our research is that we successfully reproduced the model's extrapolation behavior reported in the Code Llama paper. Specifically, if we initialize the model with RoPE from scratch and train it on sequences up to $N$ tokens, it cannot extrapolate beyond its pretraining length at all. However, if we then apply base frequency scaling and optimize for a few steps on sequences up to $M>N$ tokens, the model learns to extrapolate not only beyond $N$ tokens, but even for numbers larger than $M$.

This behavior has been observed before in a standard repository-level pretraining setup. In our work, we confirm this finding once again and provide an insight into the case where $M = N$, showing that it still works just fine.

<u>Slide #16</u>
#### Masked loss vs full loss

The second varied parameter in our experiments is gradient masking. The model derives its learning signal from two sources: composed context and completion file. The matching of their distributions depends on the context composer's choice. If the distributions do not match, backpropagating from all tokens can introduce unwanted bias to the model. For example, learning JSON file completions would be irrelevant if the goal is to have the model perform well solely on code. However, including different file formats in the context makes sense if they are relevant to the completion. This problem can be addressed through gradient masking. We can simply exclude non-completion tokens from the backward computational graph during training.

We compared both approaches using composers that produce similar distributions to the completion. Our results demonstrate that masking leads to a statistically significant performance decrease. Nevertheless, the drop in metrics is marginal, less than 0.2 EM points on average. Consequently, we conclude that this performance difference is insufficient to justify avoiding diverse distributions and excluding a wide range of composers during repository-level pretraining.

<u>Slide #17</u>
#### Takeaways

Let me repeat our four takeaways for you: ...  
That's basically all I wanted to say. Thank you for your attention! And I look forward to your questions.

<u>Slide #18</u>
#### Appendix: Hyperparameters

Everything is on the slide.