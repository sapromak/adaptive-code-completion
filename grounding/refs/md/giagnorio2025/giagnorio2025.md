# Why Personalizing Deep Learning-Based Code Completion Tools Matters

ALESSANDRO GIAGNORIO, Università della Svizzera italiana, Switzerland ALBERTO MARTIN-LOPEZ, Università della Svizzera italiana, Switzerland GABRIELE BAVOTA, Università della Svizzera italiana, Switzerland

Deep learning (DL)-based code completion tools have revolutionized software development by providing unprecedented code generation capabilities. The DL models behind these tools are usually trained on large amounts of code from thousands of software repositories. This makes them good in learning natural coding patterns observed across many training instances. However, little is known about the extent to which additional training effort (fine-tuning) aimed at specializing the models towards the code base of a given organization/developer further benefits their code completion capabilities. In this work, we fill this gap by presenting solid empirical evidence answering this question. More specifically, we consider 136 developers from two organizations (Apache and Spring), two model architectures (T5 and Code Llama), and three model sizes (60M, 750M, and 7B trainable parameters). For T5 models (60M, 750M), we pre-train and fine-tune them on over 2,000 open source projects, making sure that code from the two subject organizations is not part of their training sets. Then, we compare their completion capabilities against the same models further fine-tuned on organization- and developer-specific datasets. For the Code Llama model (7B), we compare the performance of the already pre-trained model publicly available online with the same model fine-tuned via parameter-efficient fine-tuning on organization- and developer-specific datasets. Our results show that there is a boost in prediction capabilities provided by both an organization-specific and a developer-specific additional fine-tuning, with the former being particularly performant. Such a finding generalizes across (i) the two subject organizations (i.e., Apache and Spring) and (ii) models of completely different magnitude (from 60M to 7B trainable parameters). Finally, we show that DL models fine-tuned on an organization-specific dataset achieve the same completion performance of pre-trained code models used out of the box and being ∼10× larger, with consequent savings in terms of deployment and inference cost (e.g., smaller GPUs needed).

### CCS Concepts: • Software and its engineering; • Computing methodologies → Artificial Intelligence;

Additional Key Words and Phrases: Software Engineering, Artificial Intelligence, Code Recommenders, Training Strategies

#### ACM Reference Format:

Alessandro Giagnorio, Alberto Martin-Lopez, and Gabriele Bavota. 2025. Why Personalizing Deep Learning-Based Code Completion Tools Matters. 1, 1 (March 2025), [32](#page-31-0) pages. <https://doi.org/XXXXXXX.XXXXXXX>

### 1 INTRODUCTION

The automatic generation of source code has been a long lasting dream in software engineering research for many years. Thanks to the advent of large deep learning (DL) models trained on code, we moved from predicting the next token the developer is likely to type [\[15,](#page-29-0) [51\]](#page-30-0) to the generation of complete code blocks and functions [\[24\]](#page-29-1). Tools such as GitHub Copilot [\[17\]](#page-29-2) are nowadays used by millions of developers and have been shown to boost their productivity [\[49\]](#page-30-1). These

© 2025 Copyright held by the owner/author(s). Publication rights licensed to ACM.

Authors' addresses: Alessandro Giagnorio, Università della Svizzera italiana, Lugano, Switzerland, alessandro.giagnorio@usi.ch; Alberto Martin-Lopez, Università della Svizzera italiana, Lugano, Switzerland, alberto.martin@usi.ch; Gabriele Bavota, Università della Svizzera italiana, Lugano, Switzerland, gabriele.bavota@usi.ch.

Permission to make digital or hard copies of all or part of this work for personal or classroom use is granted without fee provided that copies are not made or distributed for profit or commercial advantage and that copies bear this notice and the full citation on the first page. Copyrights for components of this work owned by others than the author(s) must be honored. Abstracting with credit is permitted. To copy otherwise, or republish, to post on servers or to redistribute to lists, requires prior specific permission and/or a fee. Request permissions from permissions@acm.org.

tools are trained on a large code corpora usually mined from open source projects. For example, Copilot's training set includes 159 GB of code mined from 54M public GitHub repositories [\[17\]](#page-29-2). Given the known repetitiveness of source code [\[32\]](#page-30-2), this training process allows the DL models to learn coding patterns seen across (possibly thousands of) code files, hence enabling the generation of meaningful recommendations when facing coding contexts similar to those in the training set. While the usefulness of these code recommenders is backed-up by empirical evidence [\[49\]](#page-30-1), there is still room for improvement when it comes to their performance[1](#page-1-0) [\[45\]](#page-30-3).

One of the open questions when it comes to the adoption of DL-based code completion tools is whether their fine-tuning to the specific organization/developer using them may help in boosting performance. The idea is to perform a further training step after the "generic fine-tuning" (i.e., the one in which the DL model is trained on code coming from thousands of repositories) with the aim of specializing the DL model to a given code base (e.g., the code developed within an organization or by a specific developer). Indeed, recent evidence from the Natural Language Processing (NLP) field demonstrated that more specific training data may help in boosting the performance of DL models, without risks of catastrophic forgetting their general knowledge. For example, Eschbach-Dymanus et al. [\[25\]](#page-29-3) showed that Large Language Models employed for natural language translation may benefit of additional fine-tuning aimed at specializing them for a specific domain. In our case, the "specialized domain" could be represented by the code base of a specific organization/company or by the code changes implemented over time by a single developer. Given the availability of open source DL models pre-trained on code (see e.g., CodeBERT [\[26\]](#page-29-4), CodeT5 [\[58\]](#page-31-1), Code Llama [\[52\]](#page-30-4)), showing the effectiveness of specializing them to a given code base may be relevant for companies who want to consider the possibility to fine-tune one of these models on their code base with the goal of deploying an in-house code recommender, possibly saving costs and avoiding potential issues related to the need to share proprietary code with a third-party DL model (e.g., Copilot) to receive recommendations.

We present a large-scale empirical study investigating the extent to which personalizing DL-based code completion models helps in boosting their performance. We focus on two different levels of personalization, related to a whole software organization and a single developer. The former represents the scenario of a company specializing a single model on all software projects it runs. The latter answers the interesting research question of whether a deep level of personalization (down to the single developer) is really worthwhile. Indeed, a developer-specific personalization might be impractical, requiring the deployment and maintenance of several models. Still, if the gain in performance is major, then it could be considered in specific cases (e.g., a small team).

From an abstract point of view, we start from a DL model that has been trained on a large and generic code corpus. represents our baseline, namely a "generic" DL-based code completion tool. We then collect code changes performed over time by developers who contributed to projects run by organization . Given a developer who performed their contributions (i.e., code changes, possibly spanning multiple projects run by ) over a time period , we split into three parts, obtaining a -specific training, evaluation and test set. The test set features the most recent changes implemented by . We then fine-tune on the -specific training set and compare its performance to our baseline () on the -specific test set. This shows the extent to which specializing a DL-based code completion tool to a specific developer improves the support provided to on future implementation tasks. Indeed, we are adopting a time-based splitting of data, ensuring that data from the past (the oldest 's changes) is used to predict the future (the most recent 's changes). Finally, we put together all previously built developer-specific training sets, thus creating an organization-specific training set. Such dataset has been used to specialize to the organization of interest (), again

<span id="page-1-0"></span><sup>1</sup>With performance we do not refer to properties such as execution time or memory usage, but to the accuracy of the generated recommendations. Manuscript submitted to ACM

comparing the performance of this specialized model to . Also in this case the performance has been assessed on the developer-specific test sets, representing future changes that 's developers will implement.

Our study spans two organizations (Apache and Spring), two model architectures (T5 [\[50\]](#page-30-5) and Code Llama [\[52\]](#page-30-4)) and three model sizes (60M, 750M and 7B trainable parameters). For T5 models, we pre-train and fine-tune them from scratch on a code base featuring over 2M instances (Java methods with some parts masked to simulate the code completion task). These models represent our baselines (). Note that for these models we ensured that the training data used for the baselines did not include code from the organizations used as case studies (Apache and Spring). For the Code Llama model, this was not possible since the pre-trained model has been trained on a large code corpus which is not publicly available but it is very likely to include code from both organizations. Still, it is interesting to observe if even in this case, a further personalized fine-tuning helps the model. In the case of Code Llama, the pre-trained model publicly available online represents our baseline.

Concerning the specialization of the models, we mine the change history of all Java projects hosted on GitHub by each organization, identifying the developers who contributed the most to these projects. To keep the experimentation affordable, we retrieve at most the top-100 developers (in terms of contributions) for each organization, provided that their contributions result in at least 1,000 training instances and 500 test instances, to make the training and evaluation meaningful. For Apache (Spring) we mined the change history of 1,161 (68) Java repositories, obtaining 100 (36) developers who contributed across all repositories. Throughout the document, we will continue to use the notation X (Y) to refer to the numbers related to Apache (Spring), respectively. Note that for Spring we only have 36 developers since the remaining ones did not meet the 1,000 training instances requirement. Following the previously-described process, we split their change history into three sets, ending up with 100 (36) developer-specific training, evaluation and test sets. We further fine-tune our baseline on these training sets, obtaining 100 (36) developer-specialized DL-based code completion models adopting the T5 architecture. We replicate the same process using the T5 and Code Llama models for the top-10 developers from each organization (20 in total). Each of the trained models has then been tested (and compared with the baseline) on the corresponding developer-specific test set. This analysis answers the question: To what extent personalizing a DL-based code completion tool to the specific developer using it boosts its performance?

The organization-specific training sets have been obtained by merging the 100 (36) developer-specific datasets up to the latest date of the training set of each developer. This was done to ensure that data from the past is not used to predict the future (details in Section [2\)](#page-3-0). Thus, we created another 100 (36) organization-specific training sets, leading to 100 (36) new models based on the T5 architecture, plus 10 (for each organization) for the T5 and Code Llama models. This analysis answers the question: To what extent personalizing a DL-based code completion tool to a software organization boosts its performance for individual developers of the organization?

On top of what described, we performed several analyses aimed at factoring out confounding variables, like ensuring that the observed improvement is not simply due to the additional data used for further fine-tuning the baselines.

The above-summarized experiments required the training and testing of 396 different models and showed that, while a very cheap fine-tuning performed on a developer-specific dataset boosts the performance of DL-based code completion tools, the observed improvement is usually capped by the limited number of developer-specific training data which can be collected for most developers. The organization-specific fine-tuning, instead, thanks to the additional training data available, works better than a developer-specific training, and should be the obvious choice in most of cases. Indeed, when considering both organizations (i.e., Apache and Spring) together, the organization-specific models achieve statistically significant improvements in correct predictions for: (i) 64% of the 136 considered developers, with Manuscript submitted to ACM

only one case of statistically significant drop in performance (T5); (ii) 70% of the 20 considered developers, with no cases of significant drop in performance (T5 ); and (iii) 55% of the 20 considered developers, again with no cases of significant performance drop (Code Llama). Also, we demonstrate that the increase in performance observed with both specializations is not simply due to a higher number of training instances as compared to the baselines, but to their specificity. Finally, through a cost-effectiveness analysis, we show that thanks to a personalized fine-tuning, DL models can achieve code completion performance on par with those of models being ∼10× larger (e.g., an organization-specific T5 achieves the same performance of a "generic" T5 model), possibly saving costs in the long-run.

The remainder of this paper is organized as follows: Section [2](#page-3-0) details the design of our study, including data collection, model training and evaluation. Section [3](#page-11-0) analyzes the results obtained across different levels of personalization and model sizes, while Section [4](#page-25-0) summarizes the main findings. Section [5](#page-26-0) explains the validity threats and how these were mitigated. Finally, Section [6](#page-27-0) discusses related work, while Section [7](#page-28-0) concludes the paper.

### <span id="page-3-0"></span>2 STUDY DESIGN

We aim at answering the following research question:

To what extent personalizing a DL-based code completion tool can boost its performance?

We tackle this question by looking at the two levels of personalization previously mentioned: developer-specific and organization-specific. The context of our study is represented by the two organizations considered, i.e., Apache and Spring, and the code changes pushed by their top contributors to their Java projects hosted on GitHub. Table [1](#page-4-0) summarizes the models, datasets, and metrics used in each part of our empirical investigation. We will refer to the goals described in the table (Goal X) throughout the section.

### 2.1 Deep Learning Models

As representative of DL models, we adopt the T5 [\[50\]](#page-30-5) and Code Llama [\[52\]](#page-30-4). T5 is a transformer model already used in the literature to automate several code-related tasks [\[14,](#page-29-5) [27,](#page-30-6) [44,](#page-30-7) [57\]](#page-31-2), including code completion [\[18\]](#page-29-6). Raffel et al. [\[50\]](#page-30-5) proposed several variants of T5, differing in number of trainable parameters. We adopt two of them: small and large. The former features ∼60M parameters, while the latter ∼750M. All experiments described in Section [2.4](#page-9-0) have been performed using the T5 , while a subset of them features the T5 (as specified in Section [2.4\)](#page-9-0). Indeed, the trained large variants allow us, in combination with Code Llama, to investigate whether the differences observed in terms of performance after personalizing the models are valid independently from the models' size. For both T5 variants, we use the T5v1.1 implementation available via Hugging Face [\[6\]](#page-29-7). During all trainings, the batch size is set to 32 for T5 and 4 for T5 (due to its higher cost in terms of GPU memory). For both models, we adopt their default hyper-parameter values, i.e., learning rate of <sup>5</sup> <sup>×</sup> <sup>10</sup>−<sup>5</sup> , AdamW optimizer [\[41\]](#page-30-8) and linear decay scheduler.

Code Llama [\[52\]](#page-30-4) has also been proven to be effective on a broad range of Software Engineering tasks [\[16,](#page-29-8) [34,](#page-30-9) [54,](#page-31-3) [59\]](#page-31-4). Code Llama is a family of transformer models based on the general-purpose Llama 2 [\[56\]](#page-31-5) and further trained on 500B code-specific data tokens. It comes in different sizes (7B, 13B, 34B, and 70B) and versions (base model, instruction-tuned, and Python specialist). We select the base variant with 7B parameters, which is ∼10 times larger than the T5 model. Adding this model to our study allows us to: (i) compare the performance of the T5 models with state-of-the-art code models like Code Llama; (ii) investigate the impact of personalization on models with a very large number (i.e., Manuscript submitted to ACM

Table 1. Summary of models, datasets, and metrics used in this study.

<span id="page-4-0"></span>

| Baselines' Training                                                                                                               |                                                                                                                                             |                                                |
|-----------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| Models                                                                                                                            | Datasets                                                                                                                                    | Metrics                                        |
| 2 generic code-completion T5𝑠𝑚𝑎𝑙𝑙<br>(1 Apache and 1 Spring)                                                                      | 2 pre-training datasets<br>(1 Apache and 1 Spring)                                                                                          | Exact Match<br>(for best-checkpoint selection) |
| 2 generic code-completion T5𝑙𝑎𝑟𝑔𝑒<br>(1 Apache and 1 Spring)                                                                      | 2 code-completion datasets<br>(1 Apache and 1 Spring)                                                                                       |                                                |
|                                                                                                                                   | Goal 1. Evaluating Developer- and Organization-Specific Personalization                                                                     |                                                |
| Models                                                                                                                            | Datasets                                                                                                                                    | Metrics                                        |
| 136 developer-specific T5𝑠𝑚𝑎𝑙𝑙<br>(100 Apache and 36 Spring)                                                                      | 136 developer-specific train, evalua<br>tion, and test datasets<br>(100 Apache and 36 Spring)                                               | Exact Match and CrystalBLEU                    |
| 136 organization-specific T5𝑠𝑚𝑎𝑙𝑙<br>(100 Apache and 36 Spring)                                                                   | 136 organization-specific<br>train and<br>evaluation datasets<br>(100 Apache and 36 Spring)                                                 |                                                |
| Goal 2. Assessing the Impact of the Training Data Size                                                                            |                                                                                                                                             |                                                |
| Models                                                                                                                            | Datasets                                                                                                                                    | Metrics                                        |
| 20 Organization subset T5𝑠𝑚𝑎𝑙𝑙<br>(10 Apache and 10 Spring)                                                                       | 20 Organization subset train and eval<br>uation datasets                                                                                    | Exact Match and CrystalBLEU                    |
| 20 Baseline+ T5𝑠𝑚𝑎𝑙𝑙<br>(10 Apache and 10 Spring)                                                                                 | (top 10 Apache contributors and 10 Spring<br>contributors)                                                                                  |                                                |
|                                                                                                                                   | 20 Baseline+ train and evaluation<br>datasets                                                                                               |                                                |
|                                                                                                                                   | (top 10 Apache contributors and 10 Spring<br>contributors)                                                                                  |                                                |
|                                                                                                                                   | Goal 3. Evaluating the Impact of Model Size, Architecture, and Pre-training                                                                 |                                                |
| Models                                                                                                                            | Datasets                                                                                                                                    | Metrics                                        |
| 20 developer-specific T5𝑙𝑎𝑟𝑔𝑒<br>(10 Apache and 10 Spring)<br>20 organization-specific T5𝑙𝑎𝑟𝑔𝑒<br>(10 Apache and 10 Spring)       | 20 developer-specific<br>train, evalua<br>tion, and test datasets from Goal 1<br>(top 10 Apache contributors and 10 Spring<br>contributors) | Exact Match and CrystalBLEU                    |
| 20 developer-specific Code Llama<br>(10 Apache and 10 Spring)<br>20 organization-specific Code Llama<br>(10 Apache and 10 Spring) | 20 organization-specific train and eval<br>uation datasets from Goal 1<br>(top 10 Apache contributors and 10 Spring<br>contributors)        |                                                |
| Goal 4. Investigating the Cost-Performance Trade-Off                                                                              |                                                                                                                                             |                                                |
| Models                                                                                                                            | Datasets                                                                                                                                    | Metrics                                        |
| 2 generic code-completion T5𝑙𝑎𝑟𝑔𝑒<br>from Baselines' Training                                                                     | test datasets<br>20 developer-specific<br>from Goal 1                                                                                       | Exact Match                                    |
| (1 Apache and 1 Spring)<br>20 organization-specific T5𝑠𝑚𝑎𝑙𝑙                                                                       | (top 10 Apache contributors and 10 Spring<br>contributors)                                                                                  |                                                |

from Goal 1 (10 Apache and 10 Spring)

billions) of parameters; (iii) understand the generalizability of our findings to a different model architecture; and (iv) assess the impact of personalization on a pre-trained model, whose training dataset may already feature code from the organization and developers of interest. To reduce training costs for this larger model, we train Code Llama with the LoRA technique [\[33\]](#page-30-10). LoRA is a Parameter-Efficient Fine-Tuning (PEFT) method that aims to approach the performance of full-parameter fine-tuning by only training a small number of parameters. This technique freezes the pre-trained weights and replaces the gradient update matrix with two trainable low-rank matrices. This significantly reduces the number of trainable parameters (e.g., from 7B to 40M for Code Llama) while also lowering the computational cost. Following a previous study on code generation [\[59\]](#page-31-4), we set the LoRA hyperparameter values to = 32 and = 16, while using the same training configuration seen for T5 .

### 2.2 Datasets Used for Training and Testing

We describe the datasets used to train the DL models for the code completion task. In such a context, a training instance is a Java method having some contiguous tokens masked, with the model in charge of predicting them. Indeed, as done in previous work on DL-based code completion [\[18\]](#page-29-6), we work at method-level granularity. We start by describing the developer-specific (Section [2.2.1\)](#page-5-0) and the organization-specific (Section [2.2.2\)](#page-7-0) datasets. Then, we present our generic pre-training and fine-tuning datasets used to train the T5 models (Section [2.3\)](#page-8-0), which are not already trained like Code Llama.

<span id="page-5-0"></span>2.2.1 Developer-Specific Datasets. For both the developer- and organization-specific datasets, our goal is to create training/testing instances that are representative of real code changes performed by developers belonging to the organization of interest (i.e., Apache or Spring). Fig. [1](#page-6-0) illustrates the process we followed to create the developer-specific datasets. We explain it in the following.

Commits mining. We start by mining all commits from the main branch of the 1,161 Apache (68 Spring) Java projects considered in our study. We exclude commits performed by bots, not modifying Java files, and impacting too many files, likely being the result of automated operations (e.g., initial commit, rename package refactoring, etc.). Concerning the identification of bots, we apply a simple heuristic filtering out all commits performed by authors having a name containing "[bot]" and/or "GitHub". As for the commits impacting a large number of files, once mined all commits, we exclude those being outliers in terms of number of modified files, i.e., impacting more than <sup>3</sup> + 1.5 × files, where <sup>3</sup> is the third quartile and is the interquartile range of the distribution of impacted files across all commits. This process narrowed down the initial set of 1,272,556 (84,591) commits to 1,114,142 (74,906) relevant commits.

Extracting Java methods featuring new code. The next step consists in parsing the Java files impacted in the mined commits with the goal of identifying Java methods in which at least one new line has been added. We only focus on added lines and ignore the modified ones since our idea is to exploit these methods to generate training instances in which the code written by a specific developer (i.e., the added lines) is masked, and the model is in charge of predicting it. For modified lines, in theory, a developer may change a single token (or even a space) and it would be wrong to assume that the modified line represents code written by the developer. We expect this process to specialize the model towards the code changes representative of the work done by a developer and, thus, of the software organization they contribute to.

Since parsing the Java files associated with each commit is costly, we decided to perform this process only for the top-1k developers (in each organization) in terms of added lines of code. Those are the ones likely to provide enough "specialized training data" which can then be used to experiment with the developer-specific fine-tuning. Selecting these Manuscript submitted to ACM

<span id="page-6-0"></span>![](_page_6_Figure_1.jpeg)

Fig. 1. Mining process to create the developer-specific datasets.

top-1k developers is not trivial. Indeed: (i) the developers who authored the mined commits could have contributed to more than one of the 1,161 Apache (68 Spring) projects we mine, possibly using different names/emails; (ii) the change history associated with several of the subject repositories is extremely long (e.g., >20 years for Apache Commons BeanUtils [\[1\]](#page-29-9)), again increasing the likelihood that a developer changed name/email used when committing to the versioning system over time. For these reasons, before selecting the top-1k developers, we use the gambit tool [\[28\]](#page-30-11) to disambiguate the authors of all commits, associating the same author ID to commits performed by the same developer using different names. Once identified the top-1k contributors, we manually inspect the disambiguations, excluding wrong matches. In particular, given an author for which multiple GitHub accounts were matched, the first author inspected all of them discarding cases in which (i) the account cannot be traced back to the same person with high confidence; or (ii) one or more of the matched accounts does not exist anymore. This process left us with 686 (818) valid and disambiguated developers.

For each commit they performed, we clone the corresponding repository at the commit's hash and use javalang [\[4\]](#page-29-10) to parse the impacted Java files and extract all methods with at least one line added (according to the commit's diff). We subsequently discard methods that: (i) cannot be parsed (e.g., they contain syntax errors); (ii) contain the word "test" in their name (after splitting it camelCase-wise), to create a more coherent dataset of production code; (iii) contain an empty body or only comments; (iv) contain less than 15 (too simple) or more than 500 tokens (too long to handle with the subject DL models); and (v) contain non-latin characters (e.g., emojis). Through these filters, we obtained 1,148,324 (197,622) Java methods with at least one new line implemented in a given commit.

Creating training, evaluation and test sets for the top developers. As a final step, we create training/testing instances from each method extracted in the previous steps. We indicate with all lines added in a method in a specific Manuscript submitted to ACM commit. As a running example, let us assume that = {4, 5, 6, 7, 8, 14}, with the subscript number indicating the line number of each added line. If a new line is added in "isolation" (i.e., it does not have other added lines right before/after it), we mask its last tokens with randomly ranging from 3 to (50, − 1), where is the total number of tokens in the line. This is what happens in our running example to line 14. Note that we mask at least 3 and at most 50 tokens to avoid trivial completions (e.g., predicting only the last semicolon of a statement) while keeping the completion task approachable (max. 50 tokens to predict). If, instead, a block of contiguous lines is added (4 to 8 in our example), we split it into blocks of at most three lines, with empty lines (i.e., those added for formatting purpose) or lines featuring a single token (e.g., '}') not counting towards this limit. In our example, <sup>6</sup> is an empty line, therefore <sup>4</sup> to <sup>7</sup> becomes one block, and 8 a second block. We then apply the same masking procedure described for the isolated lines. This means that we compute as the total number of tokens in the block, and mask its last tokens with randomly selected as previously described. Again, we limit the maximum number of lines in a block to three to keep the complexity of the completion task reasonable. Two important points are worth being noticed. First, both completion tasks (i.e., masking of a single line or of a block of lines) simulate a developer that starts writing the needed code and receives support to complete it, with the recommendation possibly featuring multiple statements in the case of block completion. Second, a single method featuring multiple added lines in a commit can contribute multiple training/testing instances, each featuring different added line(s) masked.

The output of the aforementioned process is a dataset of code completion instances assigned to each of the 686 (818) developers, with a number of instances ranging from 42 (0) to 52,638 (20,358). For each developer, we order their dataset chronologically and keep the most recent 500 instances (code additions) as test set, while splitting the rest in the 90% least recent instances for training and the 10% most recent instances for validation. Following this procedure we make sure that only data from the past is used to predict the future, resembling a real-world scenario. Duplicates across the training and the evaluation/test sets are removed from the training set. After this process, we keep up to 100 developers from each organization, provided that they feature at least 1,000 training instances. This leads to 100 developers for Apache and 36 for Spring.

<span id="page-7-0"></span>2.2.2 Organization-Specific Datasets. We create the organization-specific datasets by exploiting the code completion instances previously created for the top developers. The idea is that instances crafted starting from the code changes of the top developers are representative of the implementation tasks usually carried out in the organization. Since also the organization-specific models will be tested on the developer-specific test sets—100 (36) different test sets—we must create 100 (36) different organization-specific training datasets, to make sure that all code changes used to build the organization-specific training instances are older than those used to build the (developer-specific) testing instances.

Fig. [2](#page-8-1) depicts the process to create the 100 organization-specific datasets for the Apache organization, one per each developer-specific test set. The same process has been used for Spring, starting from the 36 developer-specific datasets. The 100 developer-specific datasets are represented in Fig. [2](#page-8-1) using the 1 . . . <sup>100</sup> notation. The arrow associated to each developer represents the history of their changes, possibly spanning across multiple repositories (older changes to the left). As explained in Section [2.2.1,](#page-5-0) for the developer-specific dataset the 500 code completion instances derived from the most recent commits are taken as test set, while the rest is split into 90% training and 10% validation. The history of changes is not aligned among the 100 developers. This means, for example, that we have developers who started contributing in 2010 while others who started contributing in 2020. This is the reason why the arrows in Fig. [2](#page-8-1) are not aligned. When creating the organization-specific training set for the model that will be tested on 1 's test set (see the yellow arrow labeled with " 1 training"), we take the code completion instances derived from the changes performed Manuscript submitted to ACM

## <span id="page-8-1"></span>Why Personalizing Deep Learning-Based Code Completion Tools Matters 9

![](_page_8_Figure_1.jpeg)

Fig. 2. Developer- and organization-specific datasets.

by all 100 developers up to the date of the most recent change in 1 's training set (see Fig. [2\)](#page-8-1). In this way, we ensure that the 1 training set only features instances related to changes older than both 1 's validation and test set.

### <span id="page-8-0"></span>2.3 Generic Pre-training and Fine-tuning Datasets

The datasets previously described are used to specialize (i.e., fine-tune) the DL models towards the organization/developer of interest. While Code Llama is a pre-trained model that can be trained with such datasets, the T5 models call for a pre-training and generic fine-tuning phase. This section describes the datasets used for these purposes.

We start from the CodeParrot GitHub Code dataset [\[2\]](#page-29-11), featuring 19.5M Java files, 108GB of data, and including metadata about the repositories from which the code was mined. We create two subsets of it, one excluding all instances mined from Apache repositories and one all those from Spring repositories, to simulate a scenario where the generic DL-based code completion tool is not personalized towards the organization of interest (e.g., the code of the organization is not publicly available). Also, we exclude all repositories being forks of others and not having at least 100 commits, 10 contributors and 10 stars. We do this in an attempt to remove toy/personal projects. The dataset from which we excluded Apache repositories featured, after this cleaning, 2,098 projects, while the one from which we excluded Spring repositories was left with 2,057 projects. In both cases, those have been split into 40% for pre-training and 60% for fine-tuning. As done for the developer-specific datasets, we generate training instances at method-level granularity and apply the same filters previously described (e.g., remove test methods, too short/long methods, etc.). For each repository, we randomly collect at most 1,500 valid methods, to avoid biasing the dataset towards repositories with a large number of methods.

<span id="page-8-2"></span>2.3.1 Pre-training Dataset. For pre-training, we collect a total of 1,142,330 (1,091,327) methods. We use the masked language modelling training objective [\[22\]](#page-29-12), randomly masking 15% of tokens of the input method and asking the model to predict them. We split the dataset into 90% for training and 10% for validation.

<span id="page-8-3"></span>2.3.2 Fine-tuning Dataset. After removing duplicates with all developer-specific test sets, we end up with 1,080,909 (1,355,885) methods for fine-tuning. To have a fair comparison between the specialized DL models and the generic ones (i.e., the ones trained on a large dataset not featuring code coming from the organization of interest), we aim to create a generic training dataset that is as similar as possible to the developer-specific ones and, as a consequence, to the organization-specific one as well. To this end, we compute in the developer-specific datasets (all merged together) the distribution of the number of tokens masked per instance (mean=11, median=8, min=3, max=50 for Apache and Manuscript submitted to ACM

mean=13, median=10, min=3, max=50 for Spring). We tried to mirror this distribution when generating the fine-tuning instances for the generic dataset by randomly masking the end tokens of lines/blocks in its methods. We generate at most three code completion instances per method (i.e., three versions of the same method with different parts masked), obtaining 1,434,598 (1,355,862) code completion instances, which we split into 90% for training and 10% for validation. These instances have a mean of 11 (13) masked tokens, with a median of 8 (10), minimum of 3 (3) and maximum of 50 (50) tokens, resembling the characteristics of the developer-specific datasets.

### <span id="page-9-0"></span>2.4 Experimental Procedure and Data Analysis

Code Llama is a pre-trained model that supports code completion out of the box, while T5 does not. Thus, we start explaining the process used to train the two T5 variants considered in our study. We pre-train the T5 models on the dataset described in Section [2.3.1](#page-8-2) using early stopping, with checkpoints saved every epoch, a delta of 0.005, and a patience of 5 (Baselines' Training in Table [1\)](#page-4-0). This means that the models are evaluated on the pre-training validation set every epoch in terms of percentage of correctly predicted masked tokens, and the training stops if a gain in performance lower than delta is observed at each 5-epoch interval. Once pre-trained, we fine-tune the T5 variants on the generic fine-tuning dataset described in Section [2.3.2](#page-8-3) (Baselines' Training). We use the same early stopping procedure previously described for the pre-training with, however, a delta of 0.01, since we observed a faster increase in the models' prediction accuracy during fine-tuning (probably due to the fact that the models were already pre-trained). In this case, the performance of the models at each epoch has been assessed in terms of Exact Match (EM) predictions on the fine-tuning validation set (i.e., the predicted code is identical to the masked one).

The pre-trained and fine-tuned T5 models (both small and large) and the already trained Code Llama model publicly available represent our baselines (i.e., generic models trained on a large amount of code). We indicate these models with B (T5), B (T5 ) and B (Code Llama).

We use the same early stopping procedure described for the fine-tuning to further train B , B , and B , and obtain their developer-specific and organization-specific versions (Goal 1). For what concerns B , we further fine-tune 272 versions of it: 100 (36) developer-specific and 100 (36) organization-specific versions. Indeed, as explained in Section [2.2.2,](#page-7-0) even for the organization-specific models we had to create 100 (36) different training sets to avoid using data from the future to predict the past. Note that these are 272 different models, all representing further fine-tunings of B . We use the notation D to indicate the B model fine-tuned on the developer-specific dataset of the developer . Similarly, we denote with O the B model fine-tuned on the organization-specific dataset temporally aligned to the training set of (i.e., not including changes performed after the last change in 's training set).

We compare the performance of both D and O against the baseline (B ) on 's test set (Goal 1), since we want to verify whether the -specific and the organization-specific models can better predict future 's changes as compared to a generic code completion model (B ). As evaluation metric, we compute the percentage of EM predictions in the test set. While this metric has been used in several code completion works [\[11,](#page-29-13) [12,](#page-29-14) [18,](#page-29-6) [19,](#page-29-15) [30\]](#page-30-12), it represents a lower bound for the performance of a given approach. Indeed, it considers a prediction as correct only if the generated code is identical to the one to predict. This means that different but semantically equivalent code generated by the model will be considered wrong. For this reason, we complement our analysis by computing the CrystalBLEU score [\[23\]](#page-29-16) between the generated predictions and the expected code. CrystalBLEU is a variant of the BLEU score [\[48\]](#page-30-13) tailored for code and has been shown to correctly discriminate similar from dissimilar code 1.9–4.5 times more effectively when compared to BLEU [\[23\]](#page-29-16). We statistically compare the results achieved by the different models. For the EM predictions, we use the McNemar's test [\[46\]](#page-30-14), which is suitable to pairwise compare dichotomous results of two different treatments. We Manuscript submitted to ACM

complement the McNemar's test with the Odds Ratio (OR) effect size. As for the CrystalBLEU, we use the Wilcoxon signed-rank test [\[60\]](#page-31-6) and the paired Cliff's delta [\[29\]](#page-30-15) effect size.

We perform the same training procedure and data analysis using the B (T5 ) and B (Code Llama) baselines, thus obtaining specialized models D and O , compared against B , and D and O , compared against B (Goal 3). As said, such an analysis has been performed only for the top-10 developers of each organization in terms of contributed code changes, thus obtaining 40 additional T5 and 40 additional Code Llama models—10 Apache (10 Spring) developer-specific and 10 Apache (10 Spring) organization-specific.

<span id="page-10-0"></span>2.4.1 Controlling for the Training Data Size Confounding Factor. We study the impact of the amount of training provided to the models on their performance (Goal 2): since we found that the organization-specific models work better, there is a question related to the extent to which this is due to the additional training data it has seen as compared to the baselines. Indeed, since the organization-specific models are obtained via further fine-tuning the baseline, they benefit from more training data. To control for such a confounding factor, we further fine-tune B in two different ways: (i) with an organization-specific dataset capped to the same size of the developer-specific dataset, leading to Organization subset models, and (ii) with a generic dataset capped to the same size of the organization-specific dataset, leading to Baseline+ models. By comparing the performance of developer-specific with Organization subset models, since both have seen the same amount of training instances, we can understand the impact of the developer-specific data on the models' performance. Similarly, by comparing the performance of organization-specific with Baseline+ models, we can understand the impact of the organization-specific data on the models' performance. To create the generic dataset (used to fine-tune the Baseline+ models), we mined 2,354 (2,781) additional Java open source repositories hosted on GitHub which are not from Apache or Spring—thus avoiding overlap with the organization-specific datasets. These repositories have been collected using the platform by Dabić et al. [\[21\]](#page-29-17), querying it for all Java repositories having at least 10 contributors, 10 stars, and 100 commits. We processed them using the same procedure previously described for the "generic fine-tuning" dataset (Section [2.3.2\)](#page-8-3).

In practice, we created 20 "organization subset" training sets and 20 "generic" training sets, one for each of the top-10 developers of both organizations. This was done to ensure that the training sets associated to a developer would only contain instances whose date was before the first date of 's test set, i.e., to avoid using data from the future to predict the past. Due to the further training cost, these analyses have been performed only with the T5 model.

<span id="page-10-1"></span>2.4.2 Investigating Why More Specific Training Data Help. Since our findings show that more specific training data help the model, we also perform an additional analysis aimed at investigating the information items shared between the three training sets (i.e., the ones used by the baseline B , by the developer-specific, and by the organization-specific) and the 136 developer-related test sets of the two organizations. With information items we refer to:

- Domain coverage: The extent to which the domain of the data present in the test sets is covered in the training sets. Method signatures are a good proxy to this end, since they include information about supported operations (e.g., via method names) and input/output data (e.g., via return types and method arguments). We thus compute the percentage of instances in the test sets whose method signature appears in the training sets.
- Vocabulary coverage: The extent to which the vocabulary used in the test sets is covered in the training sets. We focus on literals (e.g., strings and numbers) and identifiers (e.g., method and variable/constant names), reporting the percentage of these elements in the test sets which are also present in the training sets.

• Relevance of the Training Data: The extent to which the vocabulary learned during training is actually used at inference time (i.e., present in the test sets). We compute the percentage of identifiers and literals in the training sets which can be found in the test sets.

<span id="page-11-1"></span>2.4.3 Cost-effectiveness Analysis. We also run an additional analysis aimed at understanding the cost-effectiveness of the "personalized" fine-tuning (Goal 4). Indeed, the personalized fine-tuning implies a training cost that the company would not have by just downloading a larger code-completion model already trained for such a task, and maybe exhibiting even better performance than the smaller, personalized model. We perform this cost-effectiveness analysis between T5 with "personalized fine-tuning" and T5 (being 12.5 times bigger) with a generic fine-tuning, as representative of an already generic trained model which can be downloaded and used with zero training cost. We excluded Code Llama from this part of the study since in our setting it makes no sense to consider Code Llama as representative of a general-purpose model that a company could download and use out of the box, since it likely saw the code of the two organizations (Apache and Spring) subject of our study during training. Thus, any sort of cost-effectiveness analysis comparing a non fine-tuned Code Llama versus a fine-tuned and personalized T5 would not allow to observe the actual advantage (if any) provided by personalization. Instead, by considering the T5 pre-trained and fine-tuned on a generic dataset as an example of trained model that a company can just download and use out of the box, we can guarantee that (i) this is a model that has not seen the company's code, since we excluded that code from the pre-training and fine-tuning datasets; and (ii) we are still considering a model that is 12.5 times bigger than T5 , thus allowing to observe if a much smaller model with personalized fine-tuning is able to reach similar performance of a much larger (non personalized) model. Since the T5 has only been assessed on the top-10 developers of each of the two organizations, this cost-effectiveness analysis has been performed on these 20 developers. Also, among the two personalizations of T5 (i.e., developer-specific and organization-specific), we considered the organization-specific which is more expensive (larger training sets) but achieves better performance (as we will show, aligned to those of T5 ).

To present reliable data we computed the cost of renting GPUs in Google Cloud, for both the fine-tuning of T5 and the inference performed with both models. We considered the training cost of both the cheapest (146.3k training instances) and the most expensive (888k training instances) organization-specific T5 . For the training of T5 and the inference of both T5 and T5 , we rented 1 Nvidia T4 GPU with 16GB of memory. To compute the inference cost, we generate the same 1,000 predictions with each model, and then compute the average cost of one prediction. Clearly, while the GPU used for inference is the same for all models, T5 requires a longer inference time (higher cost). We discuss the cost that an organization would have with both models given a different number of inferences performed by its developers, presenting break-even points in the best- (i.e., lowest number of training instances for the organization-specific fine-tuning, 146.3k) and worst-case (highest number, 888k) scenario. In other words, we discuss after how many inferences the company would amortize the fine-tuning cost of the personalized smaller model and start saving money.

### <span id="page-11-0"></span>3 RESULTS DISCUSSION

Tables [2](#page-12-0) and [4](#page-14-0) report the performance achieved by the baseline B (i.e., generic T5), the developer-specific and the organization-specific models in terms of exact matches (EM %) on the 100 developers' test sets of Apache and the 36 developers' test sets of Spring, respectively. In addition, for the columns referring to the personalized models we also report the number of instances in the corresponding training sets (N°), the delta in EM predictions with Manuscript submitted to ACM

<span id="page-12-0"></span>

| ID<br>Dev. | B𝑠<br>Baseline |                |              | Developer        |                 |               |                  |              | Organization     |                 |               | Dev.      | Baseline<br>ID | B𝑠           |              |              | Developer        |                 |               |                  |              | Organization     |                 |               |
|------------|----------------|----------------|--------------|------------------|-----------------|---------------|------------------|--------------|------------------|-----------------|---------------|-----------|----------------|--------------|--------------|--------------|------------------|-----------------|---------------|------------------|--------------|------------------|-----------------|---------------|
|            | %<br>EM        | N°             | %<br>EM      |                  | Δ               | OR            | N°               | %<br>EM      |                  | Δ               | OR            |           |                | %<br>EM      | N°           | %<br>EM      |                  | Δ               | OR            | N°               | %<br>EM      | Δ                |                 | OR            |
| 1          | 51.2           | 46.6k          | 60.8         | +<br>▲           | 9.60%           | 6.33          | 888.0k           | 61.8         | +<br>▲           | 10.60%          | 8.57          | 51        |                | 26.8         | 5.6k         | 26.0         | -<br>▼           | 0.80%           | 0.73          | 877.8k           | 29.8         | +<br>▲           | 3.00%           | 2.25          |
| 2          | 31.8           | 23.2k<br>20.3k | 33.2         | +<br>-<br>▲      | 1.40%           | 1.28          | 556.0k<br>830.8k | 37.0         | +<br>+<br>▲      | 5.20%           | 3.36          | 52        |                | 28.0         | 5.5k<br>5.5k | 29.0         | +<br>+<br>▲      | 1.00%           | 1.31          | 408.3k<br>846.2k | 29.0<br>50.8 | +<br>+<br>▲      | 1.00%           | 1.23          |
| 4<br>3     | 26.0<br>35.2   | 19.2k          | 25.0<br>39.0 | +<br>▼<br>▲      | 1.00%<br>3.80%  | 0.62<br>1.83  | 747.3k           | 28.2<br>44.2 | +<br>▲<br>▲      | 2.20%<br>9.00%  | 1.85<br>3.65  | 53<br>54  |                | 32.8<br>29.2 | 5.5k         | 35.2<br>30.6 | +<br>▲<br>▲      | 2.40%<br>1.40%  | 1.64<br>1.41  | 211.0k           | 33.2         | +<br>▲<br>▲      | 4.00%<br>18.00% | 12.25<br>2.82 |
| 5          | 21.4           | 18.6k          | 18.6         | -<br>▼           | 2.80%           | 0.42          | 540.5k           | 24.0         | +<br>▲           | 2.60%           | 2.30          | 55        |                | 29.4         | 5.3k         | 29.6         | +<br>▲           | 0.20%           | 1.08          | 368.6k           | 32.8         | +<br>▲           | 3.40%           | 2.31          |
| 6          | 34.6           | 17.8k          | 36.8         | +<br>▲           | 2.20%           | 2.10          | 791.4k           | 37.2         | +<br>▲           | 2.60%           | 1.93          | 56        |                | 23.6         | 5.2k         | 65.8         | +<br>▲           | 42.20%          | 53.75         | 726.8k           | 75.8         | +<br>▲           | 52.20%          | 88.00         |
| 7          | 28.8           | 17.5k          | 60.0         | +<br>▲           | 31.20%          | 9.67          | 524.8k           | 70.0         | +<br>▲           | 41.20%          | 42.20         | 57        |                | 36.0         | 5.1k         | 41.0         | +<br>▲           | 5.00%           | 2.92          | 586.0k           | 39.4         | +<br>▲           | 3.40%           | 2.70          |
| 8          | 29.0           | 17.0k          | 29.0         |                  | 0.00%           | 1.00          | 850.5k           | 32.2         | +<br>▲           | 3.20%           | 2.23          | 58        |                | 28.0         | 5.1k         | 25.0         | -<br>▼           | 3.00%           | 0.35          | 75.6k            | 28.2         | +<br>▲           | 0.20%           | 1.05          |
| 9          | 27.8           | 15.9k          | 46.2         | +<br>▲           | 18.40%          | 6.41          | 580.9k           | 48.4         | +<br>▲           | 20.60%          | 11.30         | 59        |                | 26.8         | 4.9k         | 30.0         | +<br>▲           | 3.20%           | 3.29          | 640.0k           | 30.8         | +<br>▲           | 4.00%           | 2.43          |
| 10         | 31.6           | 15.8k          | 33.2         | +<br>▲           | 1.60%           | 1.57          | 146.3k           | 33.6         | +<br>▲           | 2.00%           | 1.67          | 60        |                | 32.6         | 4.8k         | 33.4         | +<br>▲           | 0.80%           | 1.19          | 732.7k           | 37.6         | +<br>▲           | 5.00%           | 2.47          |
| 11         | 18.8           | 15.2k          | 20.0         | +<br>▲           | 1.20%           | 1.60          | 880.3k           | 20.8         | +<br>▲           | 2.00%           | 2.25          | 61        |                | 46.8         | 4.8k         | 45.8         | -<br>▼           | 1.00%           | 0.64          | 684.2k           | 43.6         | -<br>▼           | 3.20%           | 0.50          |
| 12         | 40.6           | 13.8k          | 68.8         | +<br>▲           | 28.20%          | 24.50         | 892.1k           | 69.0         | +<br>▲           | 28.40%          | 143.00        | 62        |                | 21.8         | 4.6k         | 22.0         | +<br>▲           | 0.20%           | 1.04          | 503.4k           | 25.2         | +<br>▲           | 3.40%           | 2.00          |
| 13         | 24.6           | 12.4k<br>11.2k | 27.2         | +<br>▲           | 2.60%           | 2.62          | 822.3k<br>738.7k | 30.6         | +<br>▲           | 6.00%           | 4.00          | 63        |                | 29.8         | 4.6k<br>4.6k | 31.2         | +<br>▲           | 1.40%           | 1.50          | 253.4k<br>659.2k | 32.0         | +<br>▲           | 2.20%           | 1.69          |
| 14<br>15   | 32.4<br>20.6   | 10.4k          | 21.4<br>33.8 | +<br>+<br>▲      | 1.40%<br>0.80%  | 1.70<br>1.50  | 886.0k           | 37.0<br>21.0 | +<br>+<br>▲      | 4.60%<br>0.40%  | 3.56<br>1.22  | 64<br>65  |                | 25.8<br>22.8 | 4.6k         | 29.4<br>25.6 | +<br>+<br>▲      | 3.60%<br>2.80%  | 2.12<br>2.17  | 304.1k           | 27.4<br>28.6 | +<br>+<br>▲      | 2.80%<br>4.60%  | 2.17<br>2.77  |
| 16         | 32.4           | 10.2k          | 75.0         | +<br>▲<br>▲      | 42.60%          | 24.67         | 713.2k           | 76.6         | +<br>▲<br>▲      | 44.20%          | 28.62         | 66        |                | 22.6         | 4.6k         | 23.0         | +<br>▲<br>▲      | 0.40%           | 1.20          | 816.0k           | 25.6         | +<br>▲<br>▲      | 3.00%           | 2.67          |
| 17         | 22.4           | 10.1k          | 23.2         | +<br>▲           | 0.80%           | 1.18          | 670.4k           | 27.2         | +<br>▲           | 4.80%           | 2.60          | 67        |                | 27.2         | 4.5k         | 27.0         | -<br>▼           | 0.20%           | 0.95          | 353.7k           | 31.2         | +<br>▲           | 4.00%           | 2.00          |
| 18         | 31.8           | 9.8k           | 34.2         | +<br>▲           | 2.40%           | 1.92          | 741.7k           | 34.0         | +<br>▲           | 2.20%           | 1.69          | 68        |                | 25.2         | 4.5k         | 24.2         | -<br>▼           | 1.00%           | 0.58          | 617.0k           | 25.6         | +<br>▲           | 0.40%           | 1.12          |
| 19         | 26.2           | 9.8k           | 26.6         | +<br>▲           | 0.40%           | 1.14          | 819.5k           | 28.0         | +<br>▲           | 1.80%           | 1.60          | 69        |                | 21.0         | 4.5k         | 26.2         | +<br>▲           | 5.20%           | 4.25          | 756.7k           | 37.0         | +<br>▲           | 16.00%          | 8.27          |
| 20         | 30.8           | 9.6k           | 32.2         | +<br>▲           | 1.40%           | 2.40          | 720.5k           | 35.6         | +<br>▲           | 4.80%           | 4.00          | 70        |                | 35.4         | 4.4k         | 39.2         | +<br>▲           | 3.80%           | 2.19          | 117.5k           | 42.0         | +<br>▲           | 6.60%           | 2.50          |
| 21         | 31.2           | 9.5k           | 34.4         | +<br>▲           | 3.20%           | 1.94          | 671.8k           | 35.4         | +<br>▲           | 4.20%           | 2.40          | 71        |                | 21.2         | 4.4k         | 24.8         | +<br>▲           | 3.60%           | 2.64          | 699.8k           | 28.2         | +<br>▲           | 7.00%           | 5.38          |
| 22         | 30.2           | 9.3k           | 29.2         | -<br>▼           | 1.00%           | 0.67          | 299.4k           | 30.2         |                  | 0.00%           | 1.00          | 72        |                | 19.6         | 4.3k         | 18.4         | -<br>▼           | 1.20%           | 0.54          | 790.4k           | 21.6         | +<br>▲           | 2.00%           | 1.59          |
| 23         | 19.4           | 9.3k           | 19.8         | +<br>▲           | 0.40%           | 1.20          | 544.5k           | 23.4         | +<br>▲           | 4.00%           | 3.00          | 73        |                | 24.0         | 4.3k         | 24.4         | +<br>▲           | 0.40%           | 1.25          | 701.3k           | 27.6         | +<br>▲           | 3.60%           | 2.80          |
| 24         | 25.0           | 8.9k           | 25.0         |                  | 0.00%           | 1.00          | 440.4k           | 27.8         | +<br>▲           | 2.80%           | 1.78          | 74        |                | 24.8         | 4.3k         | 25.6         | +<br>▲           | 0.80%           | 1.33          | 708.1k           | 28.4         | +<br>▲           | 3.60%           | 2.80          |
| 25         | 19.4           | 8.7k           | 22.4         | +<br>▲           | 3.00%           | 2.25          | 901.0k           | 22.6         | +<br>▲           | 3.20%           | 2.78          | 75        |                | 37.8         | 4.3k         | 39.8         | +<br>▲           | 2.00%           | 1.83          | 880.2k           | 41.4         | +<br>▲           | 3.60%           | 2.12          |
| 26         | 26.4           | 8.6k           | 29.6         | +<br>▲           | 3.20%           | 2.33          | 609.3k           | 31.8         | +<br>▲           | 5.40%           | 3.25          | 76        |                | 26.4         | 4.2k         | 25.8         | -<br>▼           | 0.60%           | 0.79          | 733.1k           | 28.4         | +<br>▲           | 2.00%           | 2.11          |
| 27         | 20.8           | 8.6k           | 46.0         | +<br>▲           | 25.20%          | 11.50         | 447.4k           | 56.0         | +<br>▲           | 35.20%          | 30.33         | 77        |                | 24.2         | 4.1k         | 27.2         | +<br>▲           | 3.00%           | 2.36          | 725.4k           | 27.8         | +<br>▲           | 3.60%           | 2.80          |
| 28         | 23.4           | 8.5k           | 24.6         | +<br>▲           | 1.20%           | 2.00          | 858.0k           | 26.0         | +<br>▲           | 2.60%           | 1.76          | 78        |                | 20.2         | 4.1k         | 23.8         | +<br>▲           | 3.60%           | 2.50          | 835.1k           | 23.0         | +<br>▲           | 2.80%           | 2.08          |
| 29         | 27.2           | 8.1k<br>8.0k   | 27.2         |                  | 0.00%           | 1.00          | 635.7k<br>650.3k | 30.8         | +<br>▲           | 3.60%           | 3.00          | 79        |                | 21.8         | 4.0k<br>3.9k | 24.2         | +<br>▲           | 2.40%           | 5.00          | 735.4k<br>29.5k  | 26.2         | +<br>▲           | 4.40%           | 2.69          |
| 30<br>31   | 25.2<br>27.6   | 8.0k           | 30.4<br>26.6 | +<br>+<br>▲<br>▲ | 1.40%<br>2.80%  | 1.78<br>2.27  | 849.7k           | 28.6<br>32.4 | +<br>+<br>▲<br>▲ | 3.40%<br>4.80%  | 2.00<br>3.67  | 80<br>81  |                | 31.8<br>35.4 | 3.9k         | 38.8<br>31.0 | -<br>+<br>▼<br>▲ | 0.80%<br>3.40%  | 0.82<br>2.55  | 780.4k           | 31.8<br>38.8 | +<br>▲           | 3.40%<br>0.00%  | 1.94<br>1.00  |
| 32         | 38.0           | 7.9k           | 38.0         |                  | 0.00%           | 1.00          | 205.9k           | 42.0         | +<br>▲           | 4.00%           | 1.45          | 82        |                | 17.0         | 3.9k         | 18.6         | +<br>▲           | 1.60%           | 1.73          | 762.8k           | 19.8         | +<br>▲           | 2.80%           | 1.82          |
| 33         | 32.6           | 7.9k           | 34.2         | +<br>▲           | 1.60%           | 1.57          | 89.6k            | 32.4         | -<br>▼           | 0.20%           | 0.95          | 83        |                | 23.0         | 3.9k         | 24.0         | +<br>▲           | 1.00%           | 1.62          | 787.5k           | 27.2         | +<br>▲           | 4.20%           | 2.91          |
| 34         | 42.6           | 7.6k           | 45.0         | +<br>▲           | 2.40%           | 1.63          | 487.1k           | 50.4         | +<br>▲           | 7.80%           | 4.25          | 84        |                | 22.0         | 3.8k         | 21.2         | -<br>▼           | 0.80%           | 0.76          | 648.8k           | 25.6         | +<br>▲           | 3.60%           | 2.50          |
| 35         | 32.4           | 7.5k           | 32.2         | -<br>▼           | 0.20%           | 0.94          | 808.7k           | 37.2         | +<br>▲           | 4.80%           | 3.67          | 85        |                | 28.6         | 3.8k         | 31.8         | +<br>▲           | 3.20%           | 2.07          | 867.6k           | 33.2         | +<br>▲           | 4.60%           | 2.92          |
| 36         | 32.8           | 7.5k           | 30.8         | -<br>▼           | 2.00%           | 0.50          | 434.1k           | 34.0         | +<br>▲           | 1.20%           | 1.32          | 86        |                | 32.2         | 3.8k         | 33.2         | +<br>▲           | 1.00%           | 1.25          | 193.6k           | 36.0         | +<br>▲           | 3.80%           | 2.46          |
| 37         | 22.2           | 7.0k           | 25.4         | +<br>▲           | 3.20%           | 2.45          | 880.3k           | 28.4         | +<br>▲           | 6.20%           | 3.58          | 87        |                | 23.6         | 3.8k         | 23.0         | -<br>▼           | 0.60%           | 0.75          | 164.0k           | 23.0         | -<br>▼           | 0.60%           | 0.79          |
| 38<br>39   | 33.0<br>35.8   | 6.9k<br>6.7k   | 73.8<br>31.2 | +<br>-<br>▲      | 38.00%<br>1.80% | 16.83<br>0.57 | 793.4k<br>119.2k | 78.4<br>32.2 | +<br>-<br>▲      | 42.60%<br>0.80% | 27.62<br>0.80 | 88<br>89  |                | 23.6<br>28.4 | 3.8k<br>3.7k | 24.8<br>28.0 | +<br>-<br>▲      | 1.20%<br>0.40%  | 1.75<br>0.86  | 490.7k<br>589.0k | 25.2<br>30.8 | +<br>+<br>▲      | 1.60%<br>2.40%  | 1.50<br>1.86  |
| 40         | 30.6           | 6.7k           | 27.6         | -<br>▼<br>▼      | 3.00%           | 0.35          | 251.0k           | 29.0         | -<br>▼<br>▼      | 1.60%           | 0.72          | 90        |                | 24.8         | 3.7k         | 26.2         | +<br>▼<br>▲      | 1.40%           | 1.78          | 23.1k            | 26.4         | +<br>▲<br>▲      | 1.60%           | 1.67          |
| 41         | 29.0           | 6.6k           | 29.6         | +<br>▲           | 0.60%           | 1.15          | 95.7k            | 33.2         | +<br>▲           | 4.20%           | 2.50          | 91        |                | 42.2         | 3.7k         | 43.0         | +<br>▲           | 0.80%           | 1.50          | 908.1k           | 47.2         | +<br>▲           | 5.00%           | 5.17          |
| 42         | 22.2           | 6.6k           | 34.8         | +<br>▲           | 12.60%          | 5.20          | 418.8k           | 38.6         | +<br>▲           | 16.40%          | 8.45          | 92        |                | 22.6         | 3.7k         | 23.2         | +<br>▲           | 0.60%           | 1.43          | 730.9k           | 25.0         | +<br>▲           | 2.40%           | 2.09          |
| 43         | 21.6           | 6.5k           | 23.0         | +<br>▲           | 1.40%           | 1.78          | 495.5k           | 28.0         | +<br>▲           | 6.40%           | 4.20          | 93        |                | 35.4         | 3.6k         | 37.6         | +<br>▲           | 2.20%           | 2.57          | 665.1k           | 38.6         | +<br>▲           | 3.20%           | 2.14          |
| 44         | 26.4           | 6.5k           | 28.2         | +<br>▲           | 1.80%           | 1.56          | 493.0k           | 30.2         | +<br>▲           | 3.80%           | 2.46          | 94        |                | 31.2         | 3.6k         | 30.2         | -<br>▼           | 1.00%           | 0.67          | 681.3k           | 33.6         | +<br>▲           | 2.40%           | 2.33          |
| 45         | 26.0           | 6.5k           | 28.0         | +<br>▲           | 2.00%           | 1.77          | 710.1k           | 31.2         | +<br>▲           | 5.20%           | 3.89          | 95        |                | 26.4         | 3.5k         | 39.2         | +<br>▲           | 12.80%          | 5.92          | 720.7k           | 83.4         | +<br>▲           | 57.00%          | 58.00         |
| 46         | 34.4           | 6.4k           | 35.2         | +<br>▲           | 0.80%           | 1.27          | 668.2k           | 39.6         | +<br>▲           | 5.20%           | 5.33          | 96        |                | 24.0         | 3.4k         | 22.6         | -<br>▼           | 1.40%           | 0.61          | 798.7k           | 27.8         | +<br>▲           | 3.80%           | 2.19          |
| 47         | 24.6           | 6.1k           | 25.6         | +<br>▲           | 1.00%           | 1.38          | 857.1k           | 29.0         | +<br>▲           | 4.40%           | 2.69          | 97        |                | 18.6         | 3.4k         | 20.6         | +<br>▲           | 2.00%           | 1.77          | 769.9k           | 23.4         | +<br>▲           | 4.80%           | 3.40          |
| 48         | 34.6           | 6.1k           | 39.0         | +<br>▲           | 4.40%           | 1.96          | 807.2k           | 51.6         | +<br>▲           | 17.00%          | 6.67          | 98        |                | 32.4         | 3.3k         | 33.4         | +<br>▲           | 1.00%           | 1.45          | 887.5k           | 39.2         | +<br>▲           | 6.80%           | 7.80          |
| 49<br>50   | 27.2<br>22.8   | 5.8k<br>5.6k   | 29.0<br>24.0 | +<br>+<br>▲<br>▲ | 1.80%<br>1.20%  | 1.64<br>1.32  | 285.0k<br>604.3k | 26.6<br>28.2 | +<br>+<br>▲<br>▲ | 1.00%<br>3.80%  | 1.17<br>2.58  | 100<br>99 |                | 25.2<br>26.2 | 3.1k<br>2.1k | 28.0<br>46.8 | +<br>+<br>▲<br>▲ | 2.80%<br>20.60% | 2.17<br>10.36 | 479.4k<br>752.6k | 30.8<br>65.2 | +<br>+<br>▲<br>▲ | 5.60%<br>39.00% | 2.87<br>25.38 |

 Exact Match (EM) predictions generated by the baseline and by the personalized models

 for Apache.

Table

2.

Manuscript submitted to ACM

| Ta<br>ble<br>3.                    |
|------------------------------------|
| Cr<br>yst<br>alB<br>LE<br>U        |
| (C<br>B)                           |
| ave<br>rag<br>e<br>sco<br>re       |
| bet<br>we<br>en                    |
| the<br>bas<br>eli<br>ne<br>an<br>d |
| the                                |
| per<br>son<br>aliz<br>ed           |
| mo<br>de<br>ls                     |
| for                                |
| Ap<br>ach<br>e.                    |

<span id="page-13-0"></span>

| De<br>v.<br>ID | N°                   | CB<br>De               | vel<br>op<br>Δ<br>er                | 𝐸𝑆                        | N°                       | CB<br>Or<br>gan        | iza<br>tio<br>Δ    | n                         | 𝐸𝑆                   |
|----------------|----------------------|------------------------|-------------------------------------|---------------------------|--------------------------|------------------------|--------------------|---------------------------|----------------------|
| 1              | 46.<br>6k            | 38.<br>24<br>%         | ▲<br>+<br>18.<br>77                 | %<br>0.2<br> <br>3<br>    | 888<br>.0k               | 41.<br>28<br>%         | ▲<br>+<br>22.      | 45<br>%                   | 0.2<br> <br>9<br>    |
| 2              | 23.<br>2k            | 28.<br>75              | ▲<br>+<br>3.6<br>3                  | %<br>0.0<br>6             | 556<br>.0k               | 30.<br>82              | ▲<br>+             | 8.6<br>8<br>%             | 0.1<br>3             |
| 3              | 20.<br>3k            | 19.<br>82              | ▼<br>-<br>1.5<br>1                  | %<br>0.0<br>1             | 830<br>.8k               | 26.<br>70              | ▲<br>+             | 5.3<br>7<br>%             | 0.0<br>7             |
| 4              | 19.<br>2k            | 28.<br>07              | ▲<br>+<br>5.5<br>9                  | %<br>0.0<br>7             | 747<br>.3k               | 35.<br>09              | ▲<br>+<br>13.      | 98<br>%                   | 0.1<br>9             |
| 5              | 18.<br>6k            | 19.<br>04              | ▼<br>-<br>3.3<br>4                  | %<br>0.0<br>5             | 540<br>.5k               | 24.<br>90              | ▲<br>+             | 5.2<br>2<br>%             | 0.0<br>9             |
| 6              | 17.<br>8k            | 23.<br>12              | ▲<br>+<br>4.3<br>2                  | %<br>0.0<br>4             | 791<br>.4k               | 25.<br>35              | ▲<br>+             | 5.5<br>9<br>%             | 0.0<br>7             |
| 7              | 17.<br>5k            | 57.<br>27              | ▲<br>+<br>32.<br>83                 | %<br>0.4<br>1             | 524<br>.8k               | 69.<br>02              | ▲<br>+<br>47.      | 30<br>%                   | 0.6<br>1             |
| 8              | 17.<br>0k            | 18.<br>38              | ▼<br>-<br>0.8<br>8                  | %<br>0.0<br>2             | 850<br>.5k               | 25.<br>26              | ▲<br>+             | 5.5<br>6<br>%             | 0.0<br>8             |
| 9              | 15.<br>9k            | 42.<br>69              | ▲<br>+<br>22.<br>81                 | %<br>0.2<br>9             | 580<br>.9k               | 47.<br>53              | ▲<br>+<br>29.      | 17<br>%                   | 0.4<br>1             |
| 10             | 15.<br>8k            | 30.<br>88              | ▲<br>+<br>3.7<br>5                  | %<br>0.0<br>7             | 146<br>.3k               | 29.<br>36              | ▲<br>+             | 2.0<br>3<br>%             | 0.0<br>4             |
| 11             | 15.<br>2k            | 17.<br>81              | ▲<br>+<br>1.0<br>7                  | %<br>0.0<br>1             | 880<br>.3k               | 19.<br>81              | ▲<br>+             | 3.4<br>7<br>%             | 0.0<br>7             |
| 12             | 13.<br>8k            | 62.<br>92              | ▲<br>+<br>41.<br>15                 | %<br>0.5<br>3             | 892<br>.1k               | 66.<br>97              | ▲<br>+<br>46.      | 52<br>%                   | 0.6<br>3             |
| 13             | 12.<br>4k            | 21.<br>80              | ▲<br>+<br>2.1<br>6                  | %<br>0.0<br>2             | 822<br>.3k               | 28.<br>33              | ▲<br>+             | 8.2<br>8<br>%             | 0.1<br>1             |
| 14             | 11.<br>2k            | 21.<br>28              | ▲<br>+<br>1.6<br>3                  | %<br>0.0<br>1             | 738<br>.7k               | 27.<br>92              | ▲<br>+             | 8.5<br>1<br>%             | 0.1<br>4             |
| 15             | 10.<br>4k            | 13.<br>82              | ▲<br>+<br>2.6<br>4                  | %<br>0.0<br>7             | 886<br>.0k               | 14.<br>61              | ▲<br>+             | 3.2<br>1<br>%             | 0.1<br>0             |
| 16             | 10.<br>2k            | 72.<br>95              | ▲<br>+<br>56.<br>48                 | %<br>0.6<br>9             | 713<br>.2k               | 75.<br>13              | ▲<br>+<br>58.      | 90<br>%                   | 0.7<br>1             |
| 17             | 10.<br>1k            | 20.<br>68              | ▲<br>+<br>1.6<br>1                  | %<br>0.0<br>4             | 670<br>.4k               | 22.<br>27              | ▲<br>+             | 4.6<br>0<br>%             | 0.0<br>6             |
| 18             | 9.8<br>k             | 23.<br>84              | ▲<br>+<br>4.1<br>6                  | %<br>0.0<br>5             | 741<br>.7k               | 26.<br>63              | ▲<br>+             | 6.2<br>8<br>%             | 0.1<br>1             |
| 19             | 9.8<br>k             | 18.<br>39              | ▲<br>+<br>1.2<br>0                  | %<br>0.0<br>3             | 819<br>.5k               | 23.<br>48              | ▲<br>+             | 6.0<br>8<br>%             | 0.0<br>9             |
| 20             | 9.6<br>k             | 16.<br>62              | ▲<br>+<br>2.2<br>8                  | %<br>0.0<br>2             | 720<br>.5k               | 22.<br>59              | ▲<br>+             | 7.5<br>2<br>%             | 0.1<br>0             |
| 21             | 9.5<br>k             | 25.<br>09              | ▲<br>+<br>2.2<br>9                  | %<br>0.0<br>2             | 671<br>.8k               | 30.<br>40              | ▲<br>+             | 8.0<br>3<br>%             | 0.1<br>3             |
| 22             | 9.3<br>k             | 21.<br>21              | ▲<br>+<br>0.2<br>8                  | %<br>0.0<br>0             | 299<br>.4k               | 22.<br>77              | ▲<br>+             | 1.6<br>3<br>%             | 0.0<br>3             |
| 23             | 9.3<br>k             | 18.<br>16              | ▼<br>-<br>0.2<br>2                  | %<br>0.0<br>1             | 544<br>.5k               | 22.<br>88              | ▲<br>+             | 4.5<br>0<br>%             | 0.0<br>6             |
| 24             | 8.9<br>k             | 20.<br>58              | ▲<br>+<br>1.1<br>4                  | %<br>0.0<br>2             | 440<br>.4k               | 24.<br>57              | ▲<br>+             | 5.1<br>3<br>%             | 0.0<br>8             |
| 26<br>25       | 8.6<br>8.7<br>k<br>k | 28.<br>20.<br>23<br>18 | ▲<br>+<br>+<br>4.2<br>5.0<br>7<br>7 | %<br>0.0<br>0.0<br>7<br>6 | 609<br>901<br>.3k<br>.0k | 30.<br>19.<br>63<br>46 | ▲<br>+<br>+        | 7.4<br>4.1<br>7<br>6<br>% | 0.1<br>0.0<br>6<br>1 |
| 27             | 8.6<br>k             | 45.<br>96              | ▲<br>▲<br>+<br>26.<br>31            | %<br>%<br>0.3<br>3        | 447<br>.4k               | 57.<br>69              | ▲<br>▲<br>+<br>39. | 24<br>%<br>%              | 0.4<br>9             |
| 28             | 8.5<br>k             | 18.<br>43              | ▲<br>+<br>1.9<br>3                  | %<br>0.0<br>2             | 858<br>.0k               | 23.<br>06              | ▲<br>+             | 4.2<br>6<br>%             | 0.0<br>6             |
| 29             | 8.1<br>k             | 23.<br>18              | ▲<br>+<br>1.1<br>8                  | %<br>0.0<br>1             | 635<br>.7k               | 27.<br>90              | ▲<br>+             | 6.5<br>3<br>%             | 0.0<br>9             |
| 30             | 8.0<br>k             | 21.<br>22              | ▲<br>+<br>2.2<br>2                  | %<br>0.0<br>3             | 650<br>.3k               | 26.<br>05              | ▲<br>+             | 5.3<br>9<br>%             | 0.0<br>6             |
| 31             | 8.0<br>k             | 19.<br>17              | ▲<br>+<br>4.4<br>5                  | %<br>0.0<br>5             | 849<br>.7k               | 22.<br>60              | ▲<br>+             | 8.3<br>4<br>%             | 0.0<br>9             |
| 32             | 7.9<br>k             | 23.<br>84              | ▲<br>+<br>1.2<br>6                  | %<br>0.0<br>0             | 205<br>.9k               | 34.<br>43              | ▲<br>+             | 5.5<br>1<br>%             | 0.0<br>6             |
| 33             | 7.9<br>k             | 24.<br>53              | ▲<br>+<br>2.1<br>1                  | %<br>0.0<br>3             | 89.<br>6k                | 24.<br>08              | ▼<br>-             | 0.0<br>7<br>%             | 0.0<br>1             |
| 34             | 7.6<br>k             | 28.<br>02              | ▲<br>+<br>3.1<br>5                  | %<br>0.0<br>5             | 487<br>.1k               | 33.<br>79              | ▲<br>+<br>10.      | 68<br>%                   | 0.1<br>4             |
| 35             | 7.5<br>k             | 22.<br>44              | ▼<br>-<br>1.0<br>2                  | %<br>0.0<br>1             | 808<br>.7k               | 28.<br>51              | ▲<br>+             | 6.8<br>1<br>%             | 0.0<br>9             |
| 36             | 7.5<br>k             | 24.<br>26              | ▼<br>-<br>1.8<br>8                  | %<br>0.0<br>3             | 434<br>.1k               | 27.<br>93              | ▲<br>+             | 2.0<br>0<br>%             | 0.0<br>3             |
| 37             | 7.0<br>k             | 22.<br>59              | ▲<br>+<br>5.4<br>8                  | %<br>0.0<br>8             | 880<br>.3k               | 26.<br>37              | ▲<br>+             | 9.0<br>5<br>%             | 0.1<br>2             |
| 38             | 6.9<br>k             | 69.<br>43              | ▲<br>+<br>47.<br>43                 | %<br>0.5<br>9             | 793<br>.4k               | 73.<br>88              | ▲<br>+<br>52.      | 83<br>%                   | 0.6<br>6             |
| 39             | 6.7<br>k             | 23.<br>60              | ▼<br>-<br>2.2<br>5                  | %<br>0.0<br>2             | 119<br>.2k               | 26.<br>15              | ▲<br>+             | 0.5<br>1<br>%             | 0.0<br>2             |
| 40             | 6.7<br>k             | 21.<br>27              | ▼<br>-<br>2.5<br>7                  | %<br>0.0<br>3             | 251<br>.0k               | 23.<br>88              | ▼<br>-             | 1.1<br>8<br>%             | 0.0<br>2             |
| 41             | 6.6<br>k             | 24.<br>10              | ▲<br>+<br>1.5<br>9                  | %<br>0.0<br>1             | 95.<br>7k                | 28.<br>64              | ▲<br>+             | 7.3<br>9<br>%             | 0.1<br>1             |
| 42             | 6.6<br>k             | 33.<br>36              | ▲<br>+<br>16.<br>77                 | %<br>0.2<br>4             | 418<br>.8k               | 39.<br>02              | ▲<br>+<br>23.      | 26<br>%                   | 0.3<br>2             |
| 43             | 6.5<br>k             | 21.<br>04              | ▲<br>+<br>2.4<br>2                  | %<br>0.0<br>3             | 495<br>.5k               | 28.<br>75              | ▲<br>+             | 9.9<br>3<br>%             | 0.1<br>4             |
| 44             | 6.5<br>k             | 22.<br>93              | ▲<br>+<br>2.8<br>2                  | %<br>0.0<br>5             | 493<br>.0k               | 27.<br>15              | ▲<br>+             | 7.6<br>6<br>%             | 0.1<br>2             |
| 45             | 6.5<br>k             | 21.<br>97              | ▲<br>+<br>1.3<br>2                  | %<br>0.0<br>2             | 710<br>.1k               | 27.<br>95              | ▲<br>+             | 8.1<br>4<br>%             | 0.1<br>1             |
| 46             | 6.4<br>k             | 22.<br>97              | ▲<br>+<br>2.8<br>9                  | %<br>0.0<br>4             | 668<br>.2k               | 28.<br>74              | ▲<br>+<br>10.      | 81<br>%                   | 0.1<br>5             |
| 47             | 6.1<br>k             | 17.<br>85              | ▲<br>+<br>1.4<br>4                  | %<br>0.0<br>3             | 857<br>.1k               | 23.<br>14              | ▲<br>+             | 6.7<br>3<br>%             | 0.1<br>1             |
| 48             | 6.1<br>k             | 36.<br>64              | ▲<br>+<br>5.2<br>4                  | %<br>0.0<br>8             | 807<br>.2k               | 49.<br>96              | ▲<br>+<br>20.      | 16<br>%                   | 0.2<br>8             |
| 49             | 5.8<br>k             | 23.<br>08              | ▲<br>+<br>2.4<br>2                  | %<br>0.0<br>4             | 285<br>.0k               | 24.<br>13              | ▲<br>+             | 0.2<br>4<br>%             | 0.0<br>1             |
| 50             | 5.6<br>k             | 18.<br>65              | ▲<br>+<br>0.5<br>1                  | %<br>0.0<br>0             | 604<br>.3k               | 21.<br>96              | ▲<br>+             | 5.2<br>6<br>%             | 0.0<br>7             |

| 100            | 99            | 98             | 97            | 96            | 95             | 94            | 93            | 92            | 91             | 90            | 89            | 88            | 87            | 86            | 85             | 84            | 83            | 82            | 81            | 80            | 79            | 78            | 77            | 76            | 75            | 74            | 73            | 72            | 71             | 70            | 69             | 68            | 67            | 66            | 65            | 64            | 63            | 62            | 61            | 60            | 59            | 58            | 57            | 56             | 55            | 54            | 53             | 52            | 51            |            | De<br>v.<br>ID |  |
|----------------|---------------|----------------|---------------|---------------|----------------|---------------|---------------|---------------|----------------|---------------|---------------|---------------|---------------|---------------|----------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|----------------|---------------|----------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|---------------|----------------|---------------|---------------|----------------|---------------|---------------|------------|----------------|--|
| 2.1<br>k       | 3.1<br>k      | 3.3<br>k       | 3.4<br>k      | 3.4<br>k      | 3.5<br>k       | 3.6<br>k      | 3.6<br>k      | 3.7<br>k      | 3.7<br>k       | 3.7<br>k      | 3.7<br>k      | 3.8<br>k      | 3.8<br>k      | 3.8<br>k      | 3.8<br>k       | 3.8<br>k      | 3.9<br>k      | 3.9<br>k      | 3.9<br>k      | 3.9<br>k      | 4.0<br>k      | 4.1<br>k      | 4.1<br>k      | 4.2<br>k      | 4.3<br>k      | 4.3<br>k      | 4.3<br>k      | 4.3<br>k      | 4.4<br>k       | 4.4<br>k      | 4.5<br>k       | 4.5<br>k      | 4.5<br>k      | 4.6<br>k      | 4.6<br>k      | 4.6<br>k      | 4.6<br>k      | 4.6<br>k      | 4.8<br>k      | 4.8<br>k      | 4.9<br>k      | 5.1<br>k      | 5.1<br>k      | 5.2<br>k       | 5.3<br>k      | 5.5<br>k      | 5.5<br>k       | 5.5<br>k      | 5.6<br>k      | N°         |                |  |
| 45.<br>85      | 25.<br>45     | 24.<br>02      | 20.<br>88     | 22.<br>56     | 35.<br>58      | 19.<br>45     | 22.<br>89     | 15.<br>28     | 20.<br>84      | 19.<br>79     | 16.<br>59     | 19.<br>45     | 18.<br>09     | 23.<br>68     | 29.<br>38      | 21.<br>11     | 20.<br>72     | 19.<br>99     | 22.<br>39     | 25.<br>26     | 18.<br>30     | 21.<br>40     | 27.<br>21     | 20.<br>92     | 24.<br>94     | 17.<br>74     | 16.<br>00     | 17.<br>81     | 18.<br>85      | 27.<br>98     | 23.<br>36      | 20.<br>22     | 19.<br>44     | 21.<br>42     | 19.<br>08     | 25.<br>26     | 20.<br>90     | 18.<br>24     | 18.<br>88     | 25.<br>07     | 16.<br>60     | 21.<br>27     | 28.<br>46     | 67.<br>74      | 18.<br>15     | 20.<br>19     | 33.<br>08      | 22.<br>94     | 19.<br>14     | CB<br>%    | De             |  |
| ▲<br>+         | ▲<br>+        | ▲<br>+         | ▲<br>+        | ▲<br>+        | ▲<br>+         | ▼<br>-        | ▲<br>+        | ▼<br>-        | ▲<br>+         | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▼<br>-        | ▲<br>+        | ▲<br>+         | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+         | ▲<br>+        | ▲<br>+         | ▼<br>-        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▲<br>+        | ▼<br>-        | ▼<br>-        | ▲<br>+        | ▲<br>+        | ▼<br>-        | ▲<br>+        | ▲<br>+         | ▲<br>+        | ▲<br>+        | ▲<br>+         | ▼<br>-        | ▲<br>+        |            | vel            |  |
| 27.<br>64<br>% | 3.6<br>7<br>% | 2.7<br>6<br>%  | 1.8<br>1<br>% | 0.8<br>8<br>% | 22.<br>30<br>% | 1.8<br>1<br>% | 3.8<br>7<br>% | 0.5<br>2<br>% | 0.4<br>9<br>%  | 1.0<br>9<br>% | 0.5<br>7<br>% | 1.1<br>9<br>% | 0.1<br>3<br>% | 2.1<br>0<br>% | 5.1<br>7<br>%  | 2.2<br>5<br>% | 1.6<br>9<br>% | 1.9<br>8<br>% | 3.3<br>6<br>% | 0.5<br>3<br>% | 2.8<br>2<br>% | 5.2<br>9<br>% | 3.3<br>8<br>% | 0.7<br>3<br>% | 2.6<br>1<br>% | 0.2<br>7<br>% | 1.0<br>3<br>% | 0.9<br>6<br>% | 4.0<br>2<br>%  | 5.1<br>5<br>% | 7.6<br>8<br>%  | 0.1<br>7<br>% | 0.5<br>5<br>% | 0.8<br>9<br>% | 3.2<br>5<br>% | 6.0<br>7<br>% | 1.7<br>2<br>% | 0.0<br>8<br>% | 0.5<br>3<br>% | 1.7<br>9<br>% | 4.5<br>4<br>% | 4.6<br>8<br>% | 9.6<br>9<br>% | 52.<br>40<br>% | 1.3<br>6<br>% | 1.4<br>9<br>% | 3.1<br>1<br>%  | 0.1<br>6<br>% | 0.4<br>3<br>% | Δ          | op<br>er       |  |
| 0.3<br>5       | 0.0<br>5      | 0.0<br>4       | 0.0<br>2      | 0.0<br>3      | 0.2<br>6       | 0.0<br>3      | 0.0<br>5      | 0.0<br>2      | 0.0<br>1       | 0.0<br>1      | 0.0<br>1      | 0.0<br>2      | 0.0<br>1      | 0.0<br>4      | 0.0<br>8       | 0.0<br>5      | 0.0<br>2      | 0.0<br>3      | 0.0<br>2      | 0.0<br>0      | 0.0<br>3      | 0.0<br>8      | 0.0<br>5      | 0.0<br>1      | 0.0<br>4      | 0.0<br>0      | 0.0<br>2      | 0.0<br>2      | 0.0<br>3       | 0.0<br>8      | 0.1<br>0       | 0.0<br>0      | 0.0<br>3      | 0.0<br>1      | 0.0<br>3      | 0.0<br>8      | 0.0<br>2      | 0.0<br>2      | 0.0<br>0      | 0.0<br>2      | 0.0<br>4      | 0.0<br>7      | 0.1<br>4      | 0.6<br>3       | 0.0<br>2      | 0.0<br>2      | 0.0<br>6       | 0.0<br>0      | 0.0<br>1      | <br>𝐸𝑆<br> |                |  |
| 752<br>.6k     | 479<br>.4k    | 887<br>.5k     | 769<br>.9k    | 798<br>.7k    | 720<br>.7k     | 681<br>.3k    | 665<br>.1k    | 730<br>.9k    | 908<br>.1k     | 23.<br>1k     | 589<br>.0k    | 490<br>.7k    | 164<br>.0k    | 193<br>.6k    | 867<br>.6k     | 648<br>.8k    | 787<br>.5k    | 762<br>.8k    | 780<br>.4k    | 29.<br>5k     | 735<br>.4k    | 835<br>.1k    | 725<br>.4k    | 733<br>.1k    | 880<br>.2k    | 708<br>.1k    | 701<br>.3k    | 790<br>.4k    | 699<br>.8k     | 117<br>.5k    | 756<br>.7k     | 617<br>.0k    | 353<br>.7k    | 816<br>.0k    | 304<br>.1k    | 659<br>.2k    | 253<br>.4k    | 503<br>.4k    | 684<br>.2k    | 732<br>.7k    | 640<br>.0k    | 75.<br>6k     | 586<br>.0k    | 726<br>.8k     | 368<br>.6k    | 211<br>.0k    | 846<br>.2k     | 408<br>.3k    | 877<br>.8k    | N°         |                |  |
| 66.<br>81      | 30.<br>85     | 31.<br>13      | 24.<br>01     | 29.<br>38     | 82.<br>67      | 23.<br>83     | 26.<br>92     | 20.<br>49     | 32.<br>85      | 20.<br>71     | 20.<br>18     | 23.<br>90     | 18.<br>23     | 26.<br>21     | 34.<br>75      | 25.<br>06     | 26.<br>66     | 23.<br>51     | 26.<br>81     | 24.<br>70     | 23.<br>65     | 24.<br>03     | 29.<br>97     | 23.<br>04     | 30.<br>56     | 20.<br>95     | 20.<br>76     | 23.<br>66     | 24.<br>38      | 34.<br>06     | 37.<br>73      | 23.<br>46     | 25.<br>20     | 25.<br>39     | 21.<br>90     | 23.<br>75     | 23.<br>65     | 21.<br>69     | 24.<br>10     | 31.<br>59     | 20.<br>65     | 28.<br>31     | 26.<br>33     | 78.<br>69      | 21.<br>02     | 23.<br>60     | 45.<br>48      | 25.<br>45     | 24.<br>10     | CB<br>%    | Or<br>gan      |  |
| ▲              | ▲             | ▲              | ▲             | ▲             | ▲              | ▲             | ▲             | ▲             | ▲              | ▲             | ▲             | ▲             | ▼             | ▲             | ▲              | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▲              | ▲             | ▲              | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▲             | ▼             | ▲             | ▲             | ▲             | ▲             | ▲              | ▲             | ▲             | ▲              | ▲             | ▲             |            |                |  |
| +              | +             | +              | +             | +             | +              | +             | +             | +             | +              | +             | +             | +             | -             | +             | +              | +             | +             | +             | +             | +             | +             | +             | +             | +             | +             | +             | +             | +             | +              | +             | +              | +             | +             | +             | +             | +             | +             | +             | -             | +             | +             | +             | +             | +              | +             | +             | +              | +             | +             |            | iza            |  |
| 49.<br>25<br>% | 8.4<br>6<br>% | 11.<br>25<br>% | 5.5<br>2<br>% | 8.1<br>0<br>% | 71.<br>25<br>% | 3.9<br>1<br>% | 6.2<br>2<br>% | 3.8<br>5<br>% | 13.<br>04<br>% | 1.3<br>9<br>% | 4.1<br>6<br>% | 4.0<br>0<br>% | 0.4<br>0<br>% | 6.1<br>9<br>% | 11.<br>16<br>% | 7.2<br>1<br>% | 7.0<br>2<br>% | 4.3<br>6<br>% | 6.1<br>2<br>% | 0.1<br>8<br>% | 6.0<br>8<br>% | 7.7<br>2<br>% | 6.3<br>4<br>% | 3.9<br>0<br>% | 7.2<br>8<br>% | 3.9<br>0<br>% | 5.3<br>5<br>% | 6.0<br>2<br>% | 10.<br>19<br>% | 9.8<br>9<br>% | 21.<br>43<br>% | 2.2<br>5<br>% | 6.7<br>3<br>% | 5.0<br>6<br>% | 5.8<br>5<br>% | 5.4<br>1<br>% | 4.0<br>3<br>% | 5.1<br>7<br>% | 0.1<br>8<br>% | 9.1<br>7<br>% | 6.9<br>7<br>% | 2.7<br>5<br>% | 8.3<br>0<br>% | 63.<br>57<br>% | 4.0<br>1<br>% | 4.9<br>0<br>% | 19.<br>79<br>% | 1.1<br>4<br>% | 6.0<br>3<br>% | Δ          | tio<br>n       |  |
| 0.6<br>2       | 0.1<br>2      | 0.1<br>8       | 0.0<br>7      | 0.1<br>4      | 0.7<br>9       | 0.0<br>5      | 0.1<br>0      | 0.0<br>6      | 0.2<br>3       | 0.0<br>3      | 0.0<br>4      | 0.0<br>5      | 0.0<br>0      | 0.0<br>9      | 0.1<br>8       | 0.1<br>3      | 0.1<br>1      | 0.0<br>6      | 0.0<br>6      | 0.0<br>1      | 0.0<br>9      | 0.1<br>1      | 0.1<br>1      | 0.0<br>6      | 0.1<br>1      | 0.0<br>5      | 0.1<br>0      | 0.1<br>0      | 0.1<br>3       | 0.1<br>5      | 0.2<br>8       | 0.0<br>6      | 0.1<br>0      | 0.0<br>9      | 0.0<br>5      | 0.0<br>7      | 0.0<br>7      | 0.0<br>8      | 0.0<br>4      | 0.1<br>3      | 0.0<br>9      | 0.0<br>6      | 0.1<br>3      | 0.7<br>6       | 0.0<br>6      | 0.0<br>4      | 0.2<br>8       | 0.0<br>3      | 0.0<br>9      | <br>𝐸𝑆<br> |                |  |

Manuscript submitted to ACM

 and by the per- Table 5. CrystalBLEU (CB) average score between the baseline and the personalizedmodelsfor Spring.

 ID

N° CB %

8.6k

14.47 ▲ +

0.48% 0.00

8.4k

29.10 ▲ +

5.58% 0.11

7.6k

16.95 ▲ +

2.77% 0.04

7.6k

27.34 ▲ + 10.73% 0.13

7.2k

18.15 ▲ +

1.15% 0.04

5.6k

14.75 ▲ +

2.61% 0.05

4.5k

18.10 ▲ +

0.10% 0.00

4.3k

19.49 ▲ +

0.95% 0.00

3.0k

18.08 ▲ +

2.53% 0.04

2.9k

21.99 ▲ +

6.12% 0.13

2.5k

19.64 ▲ +

2.63% 0.06

2.2k

21.33 ▲ +

2.33% 0.03

2.1k

18.65 ▲ +

3.40% 0.05

2.0k

23.21 ▲ +

2.35% 0.05

2.0k

19.58 ▲ +

3.22% 0.05

1.6k

17.92 ▼ -

0.07% 0.00

1.6k

21.66 ▲ +

3.02% 0.03

1.5k

17.77 ▲ +

2.96% 0.08

1.4k

20.92 ▲ +

0.45% 0.02

1.3k

17.26 ▲ +

2.50% 0.07

1.1k

22.63 ▲ +

1.42% 0.02

1.1k

17.59 ▲ +

3.29% 0.09

1.0k

18.90 ▲ +

1.08% 0.01

1.0k

23.08 ▲ +

2.13% 0.05

1.0k

17.68 ▲ +

2.15% 0.05

1.0k

24.60 ▲ +

3.02% 0.04

10.3k

10.1k

22.04 ▲ +

4.39% 0.06

24.36 ▲ +

3.48% 0.07

10.7k

19.68 ▲ +

4.57% 0.09

11.2k

18.66 ▲ +

2.83% 0.06

11.4k

20.21 ▲ +

3.71% 0.10

12.6k

23.71 ▲ +

4.61% 0.10

12.7k

17.74 ▲ +

2.46% 0.06

13.4k

18.02 ▲ +

0.15% 0.02

16.9k

22.95 ▲ +

6.43% 0.14

17.9k

21.10 ▲ +

1.98% 0.02

228.6k

188.0k

222.0k

226.5k

223.8k

243.1k

201.5k

193.0k

194.7k

230.8k

172.3k

22.1k

64.1k

225.8k

223.0k

238.7k

238.7k

233.6k

17.6k

211.9k

175.4k

193.7k

147.8k

31.3k

233.5k

203.0k

228.3k

222.0k

152.7k

232.6k

35.4k

239.8k

192.6k

31.5k

196.2k

157.5k

23.96 ▲ +

0.50% 0.02

22.86 ▲ +

4.89% 0.11

24.02 ▲ +

4.99% 0.08

24.56 ▲ +

5.54% 0.11

24.32 ▲ + 10.63% 0.22

21.88 ▲ +

1.07% 0.01

26.17 ▲ + 11.21% 0.23

22.88 ▲ +

1.78% 0.03

24.56 ▲ + 10.16% 0.20

21.52 ▲ +

2.48% 0.04

25.57 ▲ +

7.37% 0.14

26.12 ▲ +

8.58% 0.16

26.39 ▲ +

5.13% 0.10

23.81 ▲ +

8.34% 0.13

24.59 ▲ +

3.82% 0.09

27.24 ▲ +

8.90% 0.18

23.86 ▲ +

8.59% 0.17

20.36 ▲ +

3.12% 0.08

25.19 ▲ +

5.64% 0.09

28.92 ▲ + 10.52% 0.16

20.63 ▲ +

7.88% 0.15

22.17 ▲ +

4.77% 0.07

31.58 ▲ + 13.67% 0.20

16.91 ▲ +

1.78% 0.03

29.24 ▲ +

6.33% 0.12

17.15 ▲ +

2.33% 0.06

26.07 ▲ +

7.43% 0.13

29.56 ▲ +

8.68% 0.15

25.42 ▲ + 10.72% 0.22

23.41 ▲ +

7.36% 0.14

27.01 ▲ + 11.13% 0.22

27.44 ▲ +

7.92% 0.16

22.53 ▲ +

6.05% 0.14

21.63 ▲ +

4.94% 0.09

26.49 ▲ + 10.81% 0.21

25.13 ▲ +

5.80% 0.08

Δ

| | N°

Developer

 Organization

CB %

Δ

| |

Table 4. Exact Match (EM) predictions

 generated

 by the baseline

| Organization<br>EM<br>N°<br>OR<br>Developer<br>Δ<br>EM<br>N°<br>B𝑠<br>Baseline<br>EM                                                   |
|----------------------------------------------------------------------------------------------------------------------------------------|
| ▲<br>%<br>27.4<br>228.6k<br>2.67<br>3.00%<br>+<br>▲<br>%<br>26.8<br>17.9k<br>%<br>23.8                                                 |
| 26.0<br>188.0k<br>1.53<br>1.60%<br>+<br>▲<br>24.4<br>16.9k<br>22.8                                                                     |
| 21.0<br>222.0k<br>0.65<br>1.40%<br>-<br>▼<br>18.2<br>13.4k<br>19.6                                                                     |
| 19.4<br>226.5k<br>1.62<br>1.00%<br>+<br>▲<br>19.2<br>12.7k<br>18.2                                                                     |
| ▲<br>28.2<br>223.8k<br>1.60<br>1.20%<br>+<br>▲<br>27.2<br>12.6k<br>26.0                                                                |
| ▲<br>25.6<br>243.1k<br>1.60<br>1.20%<br>+<br>▲<br>22.2<br>11.4k<br>21.0                                                                |
| 27.8<br>201.5k<br>1.62<br>1.00%<br>+<br>▲<br>25.4<br>11.2k<br>24.4                                                                     |
| ▲<br>22.2<br>193.0k<br>3.33<br>2.80%<br>+<br>▲<br>21.0<br>10.7k<br>18.2                                                                |
| ▲<br>26.4<br>194.7k<br>1.29<br>1.00%<br>+<br>▲<br>23.6<br>10.3k<br>22.6                                                                |
| ▲<br>23.8<br>230.8k<br>2.29<br>4.40%<br>+<br>▲<br>25.8<br>10.1k<br>21.4                                                                |
| ▲<br>21.0<br>172.3k<br>1.38<br>0.60%<br>+<br>▲<br>20.4<br>8.6k<br>19.8                                                                 |
| ▲<br>30.8<br>22.1k<br>2.07<br>3.00%<br>+<br>▲<br>30.0<br>8.4k<br>27.0                                                                  |
| ▲<br>31.6<br>64.1k<br>2.86<br>2.60%<br>+<br>▲<br>32.6<br>7.6k<br>30.0                                                                  |
| 34.8<br>225.8k<br>6.62<br>9.00%<br>+<br>▲<br>35.0<br>7.6k<br>26.0                                                                      |
| 19.8<br>223.0k<br>0.91<br>0.20%<br>-<br>▼<br>18.2<br>7.2k<br>18.4                                                                      |
| 20.4<br>238.7k<br>1.71<br>1.00%<br>+<br>▲<br>16.8<br>5.6k<br>15.8                                                                      |
| 24.4<br>25.6<br>238.7k<br>233.6k<br>0.92<br>1.20<br>0.20%<br>0.40%<br>+<br>-<br>▼<br>▲<br>20.4<br>22.6<br>4.5k<br>4.3k<br>20.6<br>22.2 |
| 24.8<br>17.6k<br>1.88<br>1.40%<br>+<br>▲<br>25.0<br>3.0k<br>23.6                                                                       |
| 21.2<br>211.9k<br>1.75<br>1.80%<br>+<br>▲<br>19.8<br>2.9k<br>18.0                                                                      |
| 18.4<br>175.4k<br>2.00<br>1.20%<br>+<br>▲<br>16.2<br>2.5k<br>15.0                                                                      |
| 22.4<br>193.7k<br>1.36<br>0.80%<br>+<br>▲<br>22.4<br>2.2k<br>21.6                                                                      |
| 26.2<br>147.8k<br>2.33<br>2.40%<br>+<br>▲<br>24.6<br>2.1k<br>22.2                                                                      |
| 25.4<br>31.3k<br>1.20<br>0.60%<br>+<br>▲<br>24.4<br>2.0k<br>23.8                                                                       |
| 19.8<br>233.5k<br>2.17<br>1.40%<br>+<br>▲<br>18.6<br>2.0k<br>17.2                                                                      |
| 25.8<br>203.0k<br>0.89<br>0.20%<br>-<br>▼<br>23.4<br>1.6k<br>23.6                                                                      |
| 24.0<br>228.3k<br>2.71<br>2.40%<br>+<br>▲<br>23.4<br>1.6k<br>21.0                                                                      |
| 20.4<br>222.0k<br>1.17<br>0.40%<br>+<br>▲<br>18.4<br>1.5k<br>18.0                                                                      |
| ▲<br>29.0<br>152.7k<br>0.73<br>0.60%<br>-<br>▼<br>26.6<br>1.4k<br>27.2                                                                 |
| ▲<br>22.8<br>232.6k<br>1.60<br>1.20%<br>+<br>▲<br>19.0<br>1.3k<br>17.8                                                                 |
| ▲<br>25.8<br>35.4k<br>2.00<br>2.00%<br>+<br>▲<br>26.6<br>1.1k<br>24.6                                                                  |
| ▲<br>21.4<br>239.8k<br>1.22<br>0.40%<br>+<br>▲<br>18.4<br>1.1k<br>18.0                                                                 |
| ▲<br>23.0<br>192.6k<br>1.56<br>1.00%<br>+<br>▲<br>21.8<br>1.0k<br>20.8                                                                 |
| ▲<br>30.6<br>31.5k<br>0.73<br>1.20%<br>-<br>▼<br>27.4<br>1.0k<br>28.6                                                                  |
| ▲<br>28.0<br>196.2k<br>1.80<br>0.80%<br>+<br>▲<br>27.8<br>1.0k<br>27.0                                                                 |
| ▼<br>28.0<br>157.5k<br>1.58<br>1.40%<br>+<br>▲<br>30.4<br>1.0k<br>29.0                                                                 |

Manuscript submitted to ACM

<span id="page-14-0"></span>Why Personalizing Deep Learning-Based Code Completion Tools Matters 15

respect to B (Δ), and the odds ratio (OR) reported by the McNemar's test [\[46\]](#page-30-14) (again, when tested against B ). The symbol ▲ associated to a Δ indicates a statistically significant increase in EM predictions with respect to B (-value <0.05); similarly, a ▼ indicates statistically significant decreases in performance. In each row, bold values indicate the model achieving the best performance on the corresponding test set. To make a concrete example, let us consider the results achieved on the test set related to developer 2 of Apache (Dev. ID = 2 in Table [2\)](#page-12-0): B achieved 31.8% of EM predictions on D<sup>2</sup> 's test set, against the 33.2% of the developer-specific model (trained on additional ∼23.2k instances), and the 37.0% of the organization-specific model (trained on additional ∼556k instances). Thus, the absolute increase in performance with respect to B is +1.40% for the developer-specific model (non statistically significant) and +5.20% for the organization-specific model. The latter increase is statistically significant, with an OR of 3.36, indicating ∼3 times higher odds to generate an EM prediction than B .

Similarly, Tables [3](#page-13-0) and [5](#page-14-0) compare the average CrystalBLEU scores (CB %) achieved by the B baseline and by the personalized models on the developers' test sets (for Apache and Spring developers, respectively). The basic idea behind CrystalBLEU is to compare non-EM predictions generated by two models, to see whether one of the two models still generates predictions closer to the target when not outputting an EM. We exclude from this analysis cases in which both models generate an EM, since the CrystalBLEU would be trivially equal to 1 for both of them. In both tables, the gap between the average CrystalBLEU scores achieved by the personalized models and by B is shown in the column Δ, while the | | column shows the effect size (Cliff's delta [\[29\]](#page-30-15)) of the difference. For example, for developer 2 of Apache (Dev. ID = 2 in Table [3\)](#page-13-0) we observe an increase of +3.63% in the CrystalBLEU score for the developer-specific model as compared to B , and an increase of +8.68% for the organization-specific model. The first increase is not statistically significant, while the latter is, with an effect size of 0.13, indicating a negligible effect of the organization-specific model in generating better predictions than B .

### 3.1 Goal 1: Evaluating Developer-Specific Personalization

In terms of exact match predictions (EM), 76% (76 out of 100) of Apache developer-specific models benefitted from the second fine-tuning (33 out of 76 are statistically significant) with an average performance improvement of 5.37% (median=2.00%) and a mean OR of 3.91 (min=1.04, max=53.75). Likewise, 83% (30 out of 36) of the Spring developer-specific models achieved better performance than B (eight out of 30 statistically significant), with an average performance increase of 1.77% (median=1.20%) and a mean OR of 1.99 (min=1.17, max=6.62). Only a small part of the developer-specific models did not improve performance, namely 24 models for Apache (mean=-1.23%, median=-1.00%) and six for Spring (mean=-0.63%, median=-0.40%). Out of these, only three performance decreases were statistically significant (all in Apache, Dev. ID = 5, 40, 58). On top of these, four Apache models achieved exactly the same EM predictions of B (Dev. ID = 8, 24, 29, 32).

As it can be observed in Tables [2](#page-12-0) and [4,](#page-14-0) there are several developers which clearly represent (positive) outliers in terms of achieved increase in performance (see e.g., Dev. ID = 7 for Apache and Dev. ID = 14 for Spring). We inspected their test sets to understand why a developer-specific model was working so well as compared to B . We found that these developers implemented a significant amount of project-specific boilerplate code (e.g., toString, compareTo), thus their training and test sets shared similar code structures. These are typical code elements which nowadays can be "delegated" to an AI assistant. Still, the generic baseline model failed in predicting their completions due to the lack of project-specific code. As an illustration, the test set of developer 57 of Apache features a completion on the getLongnvarcharColumn method, whose purpose is to retrieve the longnvarcharColumn attribute from a data collection. The developer-specific model, having knowledge about the code base on which the developer works, was able to predict the need to invoke Manuscript submitted to ACM

readProperty to retrieve the attribute (as done in other code locations in the developer-specific training set), while the baseline model lacked such a piece of knowledge, recommending a wrong completion.

For what concerns the three developers on which the developer-specific model resulted in a statistically significant decrease of EMs, we inspected their predictions to identify patterns explaining this result. We found that sometimes these models fail in predicting the correct code (as opposed to the baseline) due to repetitions of the same suggestion multiple times or the addition of extra code tokens. Additional studies are needed to understand how to address this point, e.g., adopting a smaller learning rate for the developer-specific fine-tuning to avoid influencing too much the model towards the developer's coding style.

Table [3](#page-13-0) shows that, even when focusing on non-EM predictions, 84% of Apache developers' test sets have better predictions with the developer-specific model, with an average CrystalBLEU improvement of 6.63% (median=2.52%). Of these improvements, 34 are statistically significant, with an average (small) Cliff's delta of 0.18 (min=0.03, max=0.69). The trend observed for the Spring organization (depicted in Table [5\)](#page-14-0) is even clearer, with all developers but one (Dev. ID = 26) benefitting from better predictions with the developer-specific models (20 statistically significant, mean effect size of 0.08—min=0.03, max=0.14). The average improvement in CrystalBLEU is 2.96% (median=2.63%). All this suggests that, overall, while the developer-specific models seem to generate predictions closer to the target even when not outputting the correct prediction (i.e., overall higher CrystalBLEU), the mostly negligible/small effect size we observed tells us that the gap is not major. Still, it is worth noting that the overall positive trend observed for the developer-specific models (when looking at both EM predictions and CrystalBLEU) is the result of a very limited training effort, with developer-specific training datasets going from 1k up to 46.6k instances (column N°). As a term of comparison, B was fine-tuned on 1.4M instances.

## Summary of Findings

The overall trend we observed is that a developer-specific training tends to improve the model's code completion capabilities, with improvements being statistically significant for 30% (41 out of 136) of the studied developers in terms of EM predictions, and for 40% of developers (54 out of 136) in terms of CrystalBLEU. For both metrics, however, the magnitude of the observed improvement is limited, but still noteworthy when considering the very limited additional training that was performed (due to the limited fine-tuning data specific of a developer).

### 3.2 Goal 1: Evaluating Organization-Specific Personalization

Concerning the organization-specific customization, for the Apache organization, 93% of the models achieved better performance than B in terms of EM predictions, with 70 of these improvements being statistically significant. The average EM improvement is +7.84% (median=4.00%) with a mean OR of 7.59 (min=1.05, max=143.00). Similarly, for Spring all organization-specific models but one (Dev. ID = 36) were better than B , with 17 of these improvements being statistically significant. The average EM improvement is +2.84% (median=2.40%) with a mean OR of 2.37 (min=1.20, max=6.00). Only one model obtained a statistically significant decrease in performance across the two organizations (Dev. ID = 61 of Apache).

The organization-specific models beat the developer-specific ones in terms of EM predictions in 89% of cases for Apache and in 81% of cases for Spring. This is likely due to the larger amount of training data present in the organization-specific training sets. The confounding factor related to the size of the training set is thoroughly discussed in Section [3.3.](#page-17-0) The

analysis of the CrystalBLEU supports the conclusions obtained when analyzing the EM predictions: the organizationspecific models are superior to B in 96% of cases for Apache and in every case for Spring, achieving an average CrystalBLEU improvement of 11.07% (median=6.31) for Apache, and 6.69% (median=6.84) for Spring. In Apache, 85% of developers observe a statistically-significant improvement of CrystalBLEU, with an average effect size of 0.17 (min=0.04, max=0.79). In Spring, the differences are significant for 83% of developers, with an average effect size of 0.14 (min=0.07, max=0.23). It is worth noting that, differently from what observed for the developer-specific models, the improvements seen with the organization-specific fine-tuning (i) are more consistent (i.e., a higher percentage of developers benefitted from statistically-significant improvements); and (ii) are characterized by higher ORs (for EM) and effect sizes (for CrystalBLEU).

### Summary of Findings

The organization-specific models are the ones providing the best performance, being the best in class for 89 (29) out of the subject 100 (36) developers. The average increase in EM predictions is +7.84% (+2.84%) over the baseline. The CrystalBLEU study confirms the superiority of the organization-specific models, which outperform 96% (100%) of the baseline models, with an average improvement of +11.07% (+6.69%).

### <span id="page-17-0"></span>3.3 Goal 2: Assessing the Impact of the Training Data Size

The discussed findings indicate a ranking between the experimented models, with the organization-specific being the best, followed by the developer-specific and, finally, the baseline (B ). This ranking also reflects the amount of training data used in each training strategy (e.g., organization-specific benefited from more training data), questioning the role played by the training dataset size on the differences in performance.

We start from the superiority demonstrated by the organization-specific training over the developer-specific training. Our assumption is that the former was superior only due to the additional training data and that the latter would be superior (since it is more specific) if given the same amount of training instances. To test this assumption we train 20 additional organization-specific models (one for each of the top-10 developers of each organization) in which we cap the size of the training data to the exact same amount of training instances we collected for the corresponding developer-specific model. For example, since the developer-specific training set for Dev. ID = 1 of Apache has 46.6k instances, we randomly select the same number of instances from the corresponding organization-specific dataset, training with it what we call the Organization subset model. The left-hand side of Table [6](#page-18-0) reports the achieved results for Apache (top) and Spring (bottom). To provide more context, the table shows again the ID of the developer the test set refers to, the EM predictions achieved by the baseline (Baseline B column) and by the developer-specific model (Developer column) and, in addition to that, the EM predictions generated with the Organization subset model. As observed, when the organization-specific models benefit from the same amount of instances as the developer-specific models, their performance is overall worse. Indeed, the only statistically significant differences in terms of EM predictions (Dev. ID = 1, 4, 7, 9 of Apache and Dev. ID = 10 of Spring) are in favor of the developer-specific model and accompanied by an OR of at least 1.95. This suggests that, in the context of personalizing DL-based code completion tools, more specific data (e.g., developer-specific data) must be preferred over more generic ones (e.g., organization-specific data) when possible.

The second comparison we perform (right-hand side of Table [6\)](#page-18-0) concerns the organization-specific models (i.e., the best in class in our study) against a baseline (Baseline+ in the table) further trained on the same amount of training instances provided to the organization-specific models, although not specific to the organization (see Section [2.4.1](#page-10-0) for Manuscript submitted to ACM

|        |    | Dev. ID Baseline B𝑠 | Developer             | Organization subset |                      |    | Dev. ID Baseline B𝑠 | Organization           |           | Baseline+             |      |
|--------|----|---------------------|-----------------------|---------------------|----------------------|----|---------------------|------------------------|-----------|-----------------------|------|
|        |    | EM %                | N°                    | EM % EM %<br>Δ      | OR                   |    | EM %                | N°                     | EM % EM % | Δ                     | OR   |
|        | 1  | 51.2                | 60.8<br>46.6k<br>33.2 | 57.2 ▼ - 3.60% 2.38 |                      | 1  | 51.2                | 61.8<br>888.0k<br>37.0 |           | 48.8 ▼ - 13.00%       | 9.12 |
| Apache | 2  | 31.8                | 23.2k<br>25.0         | 33.4 ▲ + 0.20% 0.96 |                      | 2  | 31.8                | 556.0k<br>28.2         |           | 32.6 ▼ - 4.40%        | 3.00 |
|        | 3  | 26.0                | 20.3k<br>39.0         | 24.8 ▼ - 0.20% 1.07 |                      | 3  | 26.0                | 830.8k<br>44.2         |           | 27.2 ▼ - 1.00%        | 1.42 |
|        | 4  | 35.2                | 19.2k<br>18.6         | 35.2 ▼ - 3.80% 1.95 |                      | 4  | 35.2                | 747.3k<br>24.0         |           | 39.8 ▼ - 4.40%        | 3.00 |
|        | 5  | 21.4                | 18.6k<br>36.8         | 20.4 ▲ + 1.80% 0.50 | Apache               | 5  | 21.4                | 540.5k<br>37.2         |           | 24.4 ▲ + 0.40%        | 0.89 |
|        | 6  | 34.6                | 17.8k<br>60.0         | 36.2 ▼ - 0.60% 1.21 |                      | 6  | 34.6                | 791.4k<br>70.0         |           | 38.4 ▲ + 1.20%        | 0.73 |
|        | 7  | 28.8                | 17.5k<br>29.0         | 51.8 ▼ - 8.20% 2.64 |                      | 7  | 28.8                | 524.8k<br>32.2         |           | 46.4 ▼ - 23.60% 14.11 |      |
|        | 8  | 29.0                | 17.0k<br>46.2         | 28.4 ▼ - 0.60% 1.30 |                      | 8  | 29.0                | 850.5k<br>48.4         |           | 30.4 ▼ - 1.80%        | 1.60 |
|        | 9  | 27.8                | 15.9k<br>33.2         | 37.2 ▼ - 9.00% 3.50 |                      | 9  | 27.8                | 580.9k<br>33.6         |           | 38.0 ▼ - 10.40%       | 5.33 |
|        | 10 | 31.6                | 15.8k<br>26.8         | 33.2                | 0.00% 1.00           | 10 | 31.6                | 146.3k<br>27.4         |           | 33.8 ▲ + 0.20%        | 0.96 |
|        | 1  | 23.8                | 17.9k<br>24.4         | 24.8 ▼ - 2.00% 2.11 |                      | 1  | 23.8                | 228.6k<br>26.0         |           | 24.8 ▼ - 2.60%        | 2.18 |
|        | 2  | 22.8                | 16.9k<br>18.2         | 22.2 ▼ - 2.20% 2.00 |                      | 2  | 22.8                | 188.0k<br>21.0         |           | 22.0 ▼ - 4.00%        | 3.00 |
|        | 3  | 19.6                | 13.4k<br>19.2         | 19.0 ▲ + 0.80% 0.69 |                      | 3  | 19.6                | 222.0k<br>19.4         |           | 17.8 ▼ - 3.20%        | 2.45 |
|        | 4  | 18.2                | 12.7k<br>27.2         | 17.8 ▼ - 1.40% 2.00 |                      | 4  | 18.2                | 226.5k<br>28.2         |           | 17.4 ▼ - 2.00%        | 1.91 |
| Spring | 5  | 26.0                | 12.6k<br>22.2         | 27.2                | 0.00% 1.00<br>Spring | 5  | 26.0                | 223.8k<br>25.6         | 28.2      | 0.00%                 | 1.00 |
|        | 6  | 21.0                | 11.4k<br>25.4         | 21.0 ▼ - 1.20% 1.67 |                      | 6  | 21.0                | 243.1k<br>27.8         |           | 20.4 ▼ - 5.20%        | 4.25 |
|        | 7  | 24.4                | 11.2k<br>21.0         | 27.0 ▲ + 1.60% 0.50 |                      | 7  | 24.4                | 201.5k<br>22.2         |           | 25.4 ▼ - 2.40%        | 2.20 |
|        | 8  | 18.2                | 10.7k<br>23.6         | 19.6 ▼ - 1.40% 1.88 |                      | 8  | 18.2                | 193.0k<br>26.4         |           | 19.4 ▼ - 2.80%        | 3.80 |
|        | 9  | 22.6                | 10.3k<br>25.8         | 24.0 ▲ + 0.40% 0.91 |                      | 9  | 22.6                | 194.7k<br>23.8         |           | 22.6 ▼ - 3.80%        | 2.58 |
|        | 10 | 21.4                | 10.1k                 | 22.0 ▼ - 3.80% 3.71 |                      | 10 | 21.4                | 230.8k                 |           | 20.6 ▼ - 3.20%        | 2.07 |

<span id="page-18-0"></span>Table 6. Comparison of Exact Match (EM) predictions with models trained on different datasets of the same size.

Table 7. Comparison of CrystalBLEU (CB) scores with models trained on different datasets of the same size.

<span id="page-18-1"></span>

|        | Dev. ID | Developer               | Organization subset   |    |        | Dev. ID | Organization |                |      | Baseline+             |    |
|--------|---------|-------------------------|-----------------------|----|--------|---------|--------------|----------------|------|-----------------------|----|
|        |         | N°<br>CB %              | Δ<br>CB %             | 𝐸𝑆 |        |         | N°           | CB %           | CB % | Δ                     | 𝐸𝑆 |
|        | 1       | 31.17<br>46.6k          | 23.47 ▼ - 7.70% 0.10  |    |        | 1       | 888.0k       | 44.17          |      | 20.83 ▼ - 23.34% 0.29 |    |
|        | 2       | 27.36<br>23.2k          | 24.97 ▼ - 2.39% 0.04  |    |        | 2       | 556.0k       | 30.03          |      | 23.58 ▼ - 6.45% 0.10  |    |
|        | 3       | 21.26<br>20.3k          | 20.76 ▼ - 0.50% 0.02  |    |        | 3       | 830.8k       | 25.33          |      | 25.19 ▼ - 0.14% 0.00  |    |
|        | 4       | 27.44<br>19.2k          | 22.32 ▼ - 5.12% 0.06  |    |        | 4       | 747.3k       | 29.05          |      | 22.24 ▼ - 6.81% 0.10  |    |
| Apache | 5       | 18.84<br>18.6k          | 20.64 ▲ + 1.80% 0.02  |    | Apache | 5       | 540.5k       | 23.77          |      | 24.80 ▲ + 1.03% 0.02  |    |
|        | 6       | 22.20<br>17.8k          | 18.30 ▼ - 3.90% 0.06  |    |        | 6       | 791.4k       | 22.86          |      | 25.08 ▲ + 2.22% 0.05  |    |
|        | 7       | 39.92<br>17.5k          | 33.10 ▼ - 6.82% 0.08  |    |        | 7       | 524.8k       | 59.62          |      | 31.03 ▼ - 28.59% 0.40 |    |
|        | 8       | 18.82<br>17.0k          | 19.36 ▲ + 0.54% 0.02  |    |        | 8       | 850.5k       | 24.23          |      | 23.04 ▼ - 1.19% 0.01  |    |
|        | 9       | 34.75<br>15.9k          | 21.91 ▼ - 12.84% 0.16 |    |        | 9       | 580.9k       | 39.55          |      | 24.19 ▼ - 15.36% 0.22 |    |
|        | 10      | 29.30<br>15.8k          | 28.16 ▼ - 1.14% 0.03  |    |        | 10      | 146.3k       | 28.77          |      | 30.01 ▲ + 1.24% 0.01  |    |
|        | 1       | 20.08<br>17.9k<br>22.75 | 18.81 ▼ - 1.27% 0.00  |    |        | 1       | 228.6k       | 24.35<br>27.04 |      | 17.43 ▼ - 6.92% 0.11  |    |
|        | 2       | 16.9k<br>17.24          | 18.62 ▼ - 4.13% 0.06  |    |        | 2       | 188.0k       | 22.74          |      | 17.20 ▼ - 9.84% 0.20  |    |
|        | 3       | 13.4k<br>17.93          | 17.60 ▲ + 0.36% 0.00  |    |        | 3       | 222.0k       | 22.72          |      | 17.80 ▼ - 4.94% 0.08  |    |
|        | 4       | 12.7k<br>22.90          | 15.66 ▼ - 2.27% 0.03  |    |        | 4       | 226.5k       | 26.28          |      | 16.37 ▼ - 6.35% 0.14  |    |
| Spring | 5       | 12.6k<br>20.01          | 21.54 ▼ - 1.36% 0.04  |    | Spring | 5       | 223.8k       | 27.73          |      | 21.74 ▼ - 4.54% 0.11  |    |
|        | 6       | 11.4k<br>17.59          | 17.06 ▼ - 2.95% 0.08  |    |        | 6       | 243.1k       | 22.61          |      | 15.67 ▼ - 12.06% 0.24 |    |
|        | 7       | 11.2k<br>18.70          | 18.73 ▲ + 1.14% 0.01  |    |        | 7       | 201.5k       | 24.51          |      | 15.81 ▼ - 6.80% 0.14  |    |
|        | 8       | 10.7k<br>23.99          | 16.63 ▼ - 2.07% 0.03  |    |        | 8       | 193.0k       | 28.68          |      | 15.26 ▼ - 9.25% 0.22  |    |
|        | 9       | 10.3k<br>19.49          | 24.32 ▲ + 0.33% 0.00  |    |        | 9       | 194.7k       | 25.53          |      | 22.50 ▼ - 6.18% 0.10  |    |
|        | 10      | 10.1k                   | 16.28 ▼ - 3.21% 0.03  |    |        | 10      | 230.8k       |                |      | 19.58 ▼ - 5.95% 0.10  |    |

details). When comparing Baseline+ to the organization-specific models, for 60% of developers (Dev. ID = 1, 2, 4, 7, 9 of Apache and Dev. ID = 1, 2, 3, 6, 8, 9, 10 of Spring) the organization-specific models achieve statistically significant better results in terms of EM, with an OR of at least 2.07. In no cases Baseline+ achieves statistically significant better results. Again, this supports the idea that training on more specific data (in this case, organization-specific vs general) helps in boosting performance.

The analysis of the CrystalBLEU, available in Table [7,](#page-18-1) confirms our findings in terms of EM predictions. Predictions of developer-specific models have higher similarity than Organization subset models for eight developers out of 10 for Apache (five statistically significant) and seven out of 10 for Spring (four statistically significant), while organizationspecific models outperform the Baseline+ models in seven cases out of 10 for Apache (five of which are statistically Manuscript submitted to ACM

significant) and in all cases (all statistically significant) for Spring. Only developer 5 of Apache shows a statistically significant increase in favor of the Organization subset model.

### Summary of Findings

The amount of training instances, as expected, plays a role. Indeed, organization-specific models are better than developer-specific only when the former exploit more training data than the latter (otherwise, the opposite is true). However, when controlling for the training size (and, thus, for the training cost), our findings suggest that the more specific the training data, the higher the boost in performance at inference time.

<span id="page-19-1"></span><span id="page-19-0"></span>![](_page_19_Figure_4.jpeg)

(a) Percentage of instances in the test set whose method signature is also present in the training set.

<span id="page-19-2"></span>(b) Percentage of identifiers and literals in the test set which are also present in the training set.

<span id="page-19-3"></span>(c) Percentage of identifiers and literals in the train set which are also present in the test set.

Fig. 3. Distributions of metrics correlating training and test sets across all 100 developers of Apache. Base = Baseline B , Dev = Developer, Org = Organization. Higher is better.

3.3.1 Why Do More Specific Training Data Help? Fig. [3](#page-19-0) illustrates boxplots showing information items shared between the three trainings (Base = baseline B , Dev = developer-specific, Org = organization-specific) and the 136 developer-related test sets of the two organizations, as described in Section [2.4.2.](#page-10-1)

Fig. [3a](#page-19-1) depicts the percentage of instances in the test sets whose method signature appears in the training sets. Despite being substantially smaller, the developer-specific training sets cover a similar number of signatures (median=0.116) than the baseline (median=0.119), while the organization-specific training sets cover the most signatures (median=0.175).

Fig. [3b](#page-19-2) depicts the percentage of literals (e.g., strings and numbers) and identifiers (e.g., method and variable/constant names) in the test sets which are also present in the training sets. As observed, the organization-specific training sets have the highest vocabulary coverage (median=0.58), followed by the baseline (median=0.53), and the developer-specific (median=0.38). Despite the lower vocabulary coverage of the developer-specific training sets, these are more aligned to the vocabulary used in the test sets, as illustrated in Fig. [3c,](#page-19-3) explained next.

Fig. [3c](#page-19-3) shows the percentage of identifiers and literals in the training sets which can be found in the test sets. As expected, the developer-specific training sets hold a larger ratio of relevant data (median=0.07) compared to the organization-specific and baseline training sets, whose proportion is negligible (median=∼0). Manuscript submitted to ACM

## Summary of Findings

More specific training data helps in better aligning the domain of the model to the one of the test set (Fig. [3a\)](#page-19-1). Also, the model will be more focused on the vocabulary used in the test set (Figures [3b](#page-19-2) and [3c\)](#page-19-3).

### 3.4 Goal 3: Evaluating the Impact of Model Size, Architecture, and Pre-training

In this section we analyze the extent to which our findings generalize to larger models, different architectures, and pre-trained models whose training data might already include the organizations of interest (Apache and Spring).

We start by analyzing the generalizability to larger models compared to the T5 (60M parameters) subject of the previous analyses. We replicate our experiments with our B baseline, i.e., T5 , which features 750M parameters (12.5 times more than T5). To make the experimentation affordable, the experiments are replicated only for the top-10 developers from each organization (i.e., 20 developers in total). Table [8](#page-21-0) reports the results achieved for Apache (top) and Spring (bottom) developers. As illustrated, the main findings previously discussed for T5 apply to the experiments with T5 as well: (i) the more specific the training data, the higher the boost in performance; and (ii) the organization-specific models confirm their superiority due the larger amount of training data. Indeed, in terms of exact matches, we observe higher accuracy for developer- and organization-specific models with respect to B . Furthermore, the organization-specific personalization reports a statistically significant increase in performance for six and eight out of 10 developers for Apache and Spring, respectively, with an average OR of 4.05 (min=2.00, max=12.33). This trend in terms of EM predictions is also confirmed by the analysis of the CrystalBLEU score. Table [9](#page-21-1) reports the increase in the CrystalBLEU of the developer-specific and organization-specific models with respect to the baseline B . As shown, such increase is highest for the organization-specific models, being statistically significant for 95% of them (19 out of 20), with an average effect size of 0.18 (min=0.08, max=0.48).

In addition to the experiments with T5 , we also investigate the applicability of personalization to larger pretrained code models. We focus on Code Llama in its base version featuring 7B parameters. This allows to understand whether our findings generalize also to even larger models (10 times bigger than T5 ), with different architectures (Llama-based) and already pre-trained on data likely to also feature code from the organizations of interest (since its training cutoff date is 2023 [\[52\]](#page-30-4)). Indeed, even if Code Llama training set includes code from Apache or Spring, it is still worthwhile investigating whether further specialization can boost its performance.

```
Listing 1. Masked method.
public int add(int a, int b) {
    result = <FILL_ME>
    return result;
}
                                           Listing 2. Output by Code Llama.
                                     public int add(int a, int b) {
                                          result = a + b;
                                          return result;
                                     }
                                     public int subtract(int a, int b) {
                                          result = a - b;
                                          return result;
                                     }
                                                                                       Listing 3. Expected output.
                                                                                  public int add(int a, int b) {
                                                                                      result = a + b;
                                                                                      return result;
                                                                                  }
```
When generating the predictions for the developers' test sets with Code Llama, we observed that the model tended to generate longer outputs, often spanning multiple methods, while our code completion task is capped to at most 50 tokens from the same method (see Section [2.2.1\)](#page-5-0). For example, given the masked code shown in Listing [1,](#page-20-0) referring to an add operation, Code Llama may generate a completion like the one shown in Listing [2](#page-20-1) which, while correct, includes an additional method, subtract. Instead, it should generate only the missing part of the add method, as shown in Listing [3.](#page-20-2) When computing EM predictions, this may lead to an underestimation of the Code Llama capabilities. Thus, Manuscript submitted to ACM

<span id="page-21-0"></span>Table 8. Exact Match (EM) predictions generated by the baseline and by the personalized models using T5 .

|        | Dev. ID | Baseline B𝑙 | Developer |      |               | Organization |        |      |               |       |
|--------|---------|-------------|-----------|------|---------------|--------------|--------|------|---------------|-------|
|        |         | EM %        | N°        | EM % | Δ             | OR           | N°     | EM % | Δ             | OR    |
|        | 1       | 52.8        | 46.6k     | 64.2 | ▲<br>+ 11.40% | 10.50        | 888.0k | 66.2 | ▲<br>+ 13.40% | 5.79  |
|        | 2       | 37.4        | 23.2k     | 39.8 | ▲<br>+ 2.40%  | 1.48         | 556.0k | 44.4 | ▲<br>+ 7.00%  | 2.94  |
|        | 3       | 30.6        | 20.3k     | 29.4 | ▼<br>- 1.20%  | 0.68         | 830.8k | 33.0 | ▲<br>+ 2.40%  | 1.80  |
|        | 4       | 42.6        | 19.2k     | 45.4 | ▲<br>+ 2.80%  | 2.40         | 747.3k | 44.4 | ▲<br>+ 1.80%  | 1.56  |
| Apache | 5       | 29.0        | 18.6k     | 29.2 | ▲<br>+ 0.20%  | 1.06         | 540.5k | 31.2 | ▲<br>+ 2.20%  | 1.73  |
|        | 6       | 39.0        | 17.8k     | 41.4 | ▲<br>+ 2.40%  | 1.60         | 791.4k | 43.0 | ▲<br>+ 4.00%  | 2.82  |
|        | 7       | 47.4        | 17.5k     | 66.4 | ▲<br>+ 19.00% | 6.00         | 524.8k | 74.6 | ▲<br>+ 27.20% | 12.33 |
|        | 8       | 34.0        | 17.0k     | 35.2 | ▲<br>+ 1.20%  | 1.43         | 850.5k | 37.4 | ▲<br>+ 3.40%  | 2.06  |
|        | 9       | 41.8        | 15.9k     | 54.8 | ▲<br>+ 13.00% | 6.00         | 580.9k | 55.4 | ▲<br>+ 13.60% | 7.18  |
|        | 10      | 41.6        | 15.8k     | 41.8 | ▲<br>+ 0.20%  | 1.04         | 146.3k | 42.2 | ▲<br>+ 0.60%  | 1.12  |
|        | 1       | 27.4        | 17.9k     | 28.0 | ▲<br>+ 0.60%  | 1.16         | 228.6k | 31.2 | ▲<br>+ 3.80%  | 2.27  |
|        | 2       | 24.8        | 16.9k     | 25.4 | ▲<br>+ 0.60%  | 1.12         | 188.0k | 28.2 | ▲<br>+ 3.40%  | 2.13  |
|        | 3       | 21.0        | 13.4k     | 23.2 | ▲<br>+ 2.20%  | 1.92         | 222.0k | 25.4 | ▲<br>+ 4.40%  | 3.44  |
|        | 4       | 19.0        | 12.7k     | 23.6 | ▲<br>+ 4.60%  | 2.92         | 226.5k | 23.4 | ▲<br>+ 4.40%  | 2.83  |
| Spring | 5       | 28.4        | 12.6k     | 28.6 | ▲<br>+ 0.20%  | 1.05         | 223.8k | 31.8 | ▲<br>+ 3.40%  | 2.00  |
|        | 6       | 24.0        | 11.4k     | 24.4 | ▲<br>+ 0.40%  | 1.17         | 243.1k | 27.8 | ▲<br>+ 3.80%  | 2.46  |
|        | 7       | 26.0        | 11.2k     | 28.0 | ▲<br>+ 2.00%  | 1.83         | 201.5k | 32.0 | ▲<br>+ 6.00%  | 6.00  |
|        | 8       | 21.6        | 10.7k     | 22.6 | ▲<br>+ 1.00%  | 1.42         | 193.0k | 22.0 | ▲<br>+ 0.40%  | 1.11  |
|        | 9       | 28.6        | 10.3k     | 28.8 | ▲<br>+ 0.20%  | 1.04         | 194.7k | 29.2 | ▲<br>+ 0.60%  | 1.12  |
|        | 10      | 21.6        | 10.1k     | 21.8 | ▲<br>+ 0.20%  | 1.05         | 230.8k | 26.6 | ▲<br>+ 5.00%  | 2.39  |

<span id="page-21-1"></span>Table 9. CrystalBLEU (CB) average score between the baseline and the personalized models using T5 .

|        | Dev. ID | Developer |       |               |        | Organization |       |                       |  |  |  |
|--------|---------|-----------|-------|---------------|--------|--------------|-------|-----------------------|--|--|--|
|        |         | N°        | CB %  | Δ             | 𝐸𝑆<br> | N°           | CB %  | 𝐸𝑆<br> <br>Δ          |  |  |  |
|        | 1       | 46.6k     | 41.66 | ▲<br>+ 18.70% | 0.23   | 888.0k       | 46.35 | ▲<br>+ 20.92%<br>0.27 |  |  |  |
|        | 2       | 23.2k     | 34.73 | ▲<br>+ 5.82%  | 0.09   | 556.0k       | 38.62 | ▲<br>+ 11.22%<br>0.16 |  |  |  |
|        | 3       | 20.3k     | 25.71 | ▼<br>- 0.27%  | 0.01   | 830.8k       | 29.34 | ▲<br>+ 4.18%<br>0.08  |  |  |  |
|        | 4       | 19.2k     | 28.20 | ▲<br>+ 5.40%  | 0.07   | 747.3k       | 30.10 | ▲<br>+ 5.77%<br>0.09  |  |  |  |
| Apache | 5       | 18.6k     | 25.35 | ▲<br>+ 0.82%  | 0.02   | 540.5k       | 28.61 | ▲<br>+ 4.49%<br>0.07  |  |  |  |
|        | 6       | 17.8k     | 29.81 | ▲<br>+ 4.36%  | 0.06   | 791.4k       | 29.39 | ▲<br>+ 6.06%<br>0.08  |  |  |  |
|        | 7       | 17.5k     | 56.61 | ▲<br>+ 21.78% | 0.32   | 524.8k       | 66.42 | ▲<br>+ 33.25%<br>0.48 |  |  |  |
|        | 8       | 17.0k     | 25.44 | ▲<br>+ 3.14%  | 0.03   | 850.5k       | 28.52 | ▲<br>+ 5.77%<br>0.09  |  |  |  |
|        | 9       | 15.9k     | 44.47 | ▲<br>+ 19.33% | 0.26   | 580.9k       | 45.42 | ▲<br>+ 20.77%<br>0.29 |  |  |  |
|        | 10      | 15.8k     | 33.39 | ▲<br>+ 1.08%  | 0.03   | 146.3k       | 35.36 | ▲<br>+ 3.48%<br>0.06  |  |  |  |
|        | 1       | 17.9k     | 24.18 | ▲<br>+ 0.64%  | 0.02   | 228.6k       | 29.45 | ▲<br>+ 6.71%<br>0.11  |  |  |  |
|        | 2       | 16.9k     | 27.19 | ▲<br>+ 6.86%  | 0.15   | 188.0k       | 29.04 | ▲<br>+ 10.54%<br>0.20 |  |  |  |
|        | 3       | 13.4k     | 23.51 | ▲<br>+ 6.67%  | 0.12   | 222.0k       | 27.30 | ▲<br>+ 11.08%<br>0.19 |  |  |  |
|        | 4       | 12.7k     | 25.57 | ▲<br>+ 8.84%  | 0.18   | 226.5k       | 27.35 | ▲<br>+ 10.62%<br>0.21 |  |  |  |
| Spring | 5       | 12.6k     | 24.91 | ▲<br>+ 1.50%  | 0.03   | 223.8k       | 28.94 | ▲<br>+ 6.15%<br>0.11  |  |  |  |
|        | 6       | 11.4k     | 19.55 | ▲<br>+ 1.82%  | 0.03   | 243.1k       | 28.16 | ▲<br>+ 10.22%<br>0.20 |  |  |  |
|        | 7       | 11.2k     | 22.53 | ▲<br>+ 3.23%  | 0.05   | 201.5k       | 26.53 | ▲<br>+ 8.52%<br>0.13  |  |  |  |
|        | 8       | 10.7k     | 18.93 | ▲<br>+ 1.05%  | 0.03   | 193.0k       | 25.12 | ▲<br>+ 5.84%<br>0.15  |  |  |  |
|        | 9       | 10.3k     | 28.94 | ▲<br>+ 2.87%  | 0.05   | 194.7k       | 32.55 | ▲<br>+ 6.87%<br>0.12  |  |  |  |
|        | 10      | 10.1k     | 21.18 | ▲<br>+ 1.81%  | 0.05   | 230.8k       | 28.88 | ▲<br>+ 9.71%<br>0.15  |  |  |  |

in our analysis we also include a version of Code Llama which has been fine-tuned on only 10k instances from random projects (not belonging to Apache or Spring) for one epoch, just to make the model understand the need to generate shorter completions belonging to a single method. We experimentally verified that this small fine-tuning is enough to adapt the model to the task at hand. We refer to this model as B10 .

Table [10](#page-22-0) shows the results obtained in terms of EM predictions by Code Llama (Baseline B ), the version of Code Llama fine-tuned on 10k instances (Baseline B10 ), and the developer-specific and organization-specific models, fine-tuned on top of B . The differences reported for the developer-specific and organization-specific models (Δ & OR) are with respect to B10 since, as it can be seen, the B model taken out of the box achieves a low percentage of EM predictions, for the reasons previously explained (i.e., it generates additional unrequested methods).

|        | Dev. ID | Baseline   |               |       | Developer |   |         |      |        | Organization |   |          |       |  |
|--------|---------|------------|---------------|-------|-----------|---|---------|------|--------|--------------|---|----------|-------|--|
|        |         | EM % (B𝑐 ) | EM % (B𝑐10𝑘 ) | N°    | EM %      |   | Δ       | OR   | N°     | EM %         | Δ |          | OR    |  |
|        | 1       | 8.8        | 62.6          | 46.6k | 72.4      | ▲ | + 9.80% | 9.17 | 888.0k | 74.0         | ▲ | + 11.40% | 15.25 |  |
|        | 2       | 22.6       | 54.4          | 23.2k | 56.0      | ▲ | + 1.60% | 1.36 | 556.0k | 54.2         | ▼ | - 0.20%  | 0.96  |  |
|        | 3       | 20.0       | 45.6          | 20.3k | 44.8      | ▼ | - 0.80% | 0.79 | 830.8k | 45.8         | ▲ | + 0.20%  | 1.06  |  |
|        | 4       | 19.6       | 56.8          | 19.2k | 57.8      | ▲ | + 1.00% | 1.25 | 747.3k | 59.4         | ▲ | + 2.60%  | 2.00  |  |
|        | 5       | 22.8       | 48.6          | 18.6k | 48.6      |   | 0.00%   | 1.00 | 540.5k | 47.4         | ▼ | - 1.20%  | 0.71  |  |
| Apache | 6       | 16.6       | 49.0          | 17.8k | 51.8      | ▲ | + 2.80% | 2.75 | 791.4k | 50.2         | ▲ | + 1.20%  | 1.38  |  |
|        | 7       | 36.2       | 69.8          | 17.5k | 76.6      | ▲ | + 6.80% | 4.40 | 524.8k | 80.8         | ▲ | + 11.00% | 12.00 |  |
|        | 8       | 16.6       | 46.0          | 17.0k | 47.0      | ▲ | + 1.00% | 1.20 | 850.5k | 48.6         | ▲ | + 2.60%  | 1.93  |  |
|        | 9       | 22.0       | 54.0          | 15.9k | 59.6      | ▲ | + 5.60% | 2.47 | 580.9k | 60.6         | ▲ | + 6.60%  | 5.12  |  |
|        | 10      | 25.2       | 52.6          | 15.8k | 56.2      | ▲ | + 3.60% | 1.67 | 146.3k | 57.8         | ▲ | + 5.20%  | 2.62  |  |
|        | 1       | 16.2       | 41.8          | 17.9k | 44.2      | ▲ | + 2.40% | 1.92 | 228.6k | 44.2         | ▲ | + 2.40%  | 2.71  |  |
|        | 2       | 12.0       | 38.8          | 16.9k | 41.4      | ▲ | + 2.60% | 1.93 | 188.0k | 42.2         | ▲ | + 3.40%  | 3.12  |  |
|        | 3       | 13.0       | 35.6          | 13.4k | 37.4      | ▲ | + 1.80% | 1.50 | 222.0k | 37.8         | ▲ | + 2.20%  | 1.85  |  |
|        | 4       | 10.0       | 32.8          | 12.7k | 35.6      | ▲ | + 2.80% | 1.82 | 226.5k | 35.2         | ▲ | + 2.40%  | 1.75  |  |
| Spring | 5       | 13.4       | 43.4          | 12.6k | 45.8      | ▲ | + 2.40% | 2.09 | 223.8k | 46.8         | ▲ | + 3.40%  | 2.70  |  |
|        | 6       | 8.6        | 36.8          | 11.4k | 39.4      | ▲ | + 2.60% | 2.00 | 243.1k | 39.2         | ▲ | + 2.40%  | 1.71  |  |
|        | 7       | 15.6       | 38.0          | 11.2k | 42.2      | ▲ | + 4.20% | 2.40 | 201.5k | 44.0         | ▲ | + 6.00%  | 3.50  |  |
|        | 8       | 12.8       | 39.8          | 10.7k | 40.2      | ▲ | + 0.40% | 1.08 | 193.0k | 43.2         | ▲ | + 3.40%  | 2.06  |  |
|        | 9       | 21.6       | 47.2          | 10.3k | 49.6      | ▲ | + 2.40% | 1.60 | 194.7k | 50.8         | ▲ | + 3.60%  | 1.78  |  |
|        | 10      | 13.0       | 35.6          | 10.1k | 38.6      | ▲ | + 3.00% | 1.88 | 230.8k | 43.4         | ▲ | + 7.80%  | 4.00  |  |

<span id="page-22-0"></span>Table 10. Exact Match (EM) predictions generated by the baseline and by the personalized models using Code Llama 7B.

As illustrated, personalization is effective also for Code Llama. When it comes to the developer-specific models, eight out of 10 Apache developers and all 10 Spring developers observed a boost in performance. For Apache, this is statistically significant for five developers, with an average increase in EM predictions of 5.72% and an average OR of 4.09 (min=2.47, max=9.17). As per Spring, two developers have a statistically significant improvement of EM, with a +4.2% and a +3.0% of EM predictions (ORs 2.40 and 1.88, respectively). As already observed for the T5 models, it is the organization-specific fine-tuning that brings most of the performance improvement (see Table [10\)](#page-22-0): Overall, for 11 out of 20 developers (four for Apache and seven for Spring) Code Llama got a statistically significant boost in EM predictions, with an average increase of 5.84% and an average OR of 4.99 (min=2.06, max=15.25).

The findings are consistent also when looking at the CrystalBLEU scores (Table [11\)](#page-23-0). Still focusing on the most successful personalization (i.e., organization-specific), a statistically significant increase in CrystalBLEU is observed on the test sets of 5/10 Apache and 10/10 Spring developers. For four of these developers, a two-digit increase is observed, indicating a strong impact of the personalized fine-tuning.

<span id="page-23-0"></span>Table 11. CrystalBLEU (CB) average score between the baseline and the personalized Code Llama 7B models.

|        | Dev. ID | Developer |       |               | Organization |        |       |               |        |  |
|--------|---------|-----------|-------|---------------|--------------|--------|-------|---------------|--------|--|
|        |         | N°        | CB %  | Δ             | 𝐸𝑆<br>       | N°     | CB %  | Δ             | 𝐸𝑆<br> |  |
|        | 1       | 46.6k     | 44.58 | ▲<br>+ 18.39% | 0.22         | 888.0k | 47.72 | ▲<br>+ 22.31% | 0.27   |  |
|        | 2       | 23.2k     | 38.50 | ▲<br>+ 2.52%  | 0.03         | 556.0k | 38.73 | ▲<br>+ 2.24%  | 0.04   |  |
|        | 3       | 20.3k     | 33.19 | ▲<br>+ 0.56%  | 0.01         | 830.8k | 31.95 | ▲<br>+ 0.02%  | 0.01   |  |
|        | 4       | 19.2k     | 37.31 | ▲<br>+ 2.60%  | 0.04         | 747.3k | 37.41 | ▲<br>+ 4.69%  | 0.06   |  |
|        | 5       | 18.6k     | 34.16 | ▲<br>+ 0.72%  | 0.02         | 540.5k | 33.53 | ▼<br>- 0.15%  | 0.00   |  |
| Apache | 6       | 17.8k     | 34.68 | ▲<br>+ 4.51%  | 0.06         | 791.4k | 32.60 | ▲<br>+ 0.37%  | 0.01   |  |
|        | 7       | 17.5k     | 48.18 | ▲<br>+ 12.39% | 0.17         | 524.8k | 56.10 | ▲<br>+ 22.37% | 0.32   |  |
|        | 8       | 17.0k     | 36.40 | ▲<br>+ 1.51%  | 0.01         | 850.5k | 35.71 | ▲<br>+ 3.34%  | 0.04   |  |
|        | 9       | 15.9k     | 41.45 | ▲<br>+ 8.44%  | 0.12         | 580.9k | 40.84 | ▲<br>+ 10.92% | 0.16   |  |
|        | 10      | 15.8k     | 46.83 | ▲<br>+ 7.35%  | 0.11         | 146.3k | 45.77 | ▲<br>+ 8.92%  | 0.15   |  |
|        | 1       | 17.9k     | 34.48 | ▲<br>+ 3.96%  | 0.07         | 228.6k | 33.08 | ▲<br>+ 3.96%  | 0.07   |  |
|        | 2       | 16.9k     | 34.79 | ▲<br>+ 4.92%  | 0.08         | 188.0k | 36.26 | ▲<br>+ 7.73%  | 0.12   |  |
|        | 3       | 13.4k     | 33.94 | ▲<br>+ 2.54%  | 0.03         | 222.0k | 33.60 | ▲<br>+ 3.23%  | 0.05   |  |
|        | 4       | 12.7k     | 33.59 | ▲<br>+ 5.82%  | 0.09         | 226.5k | 33.50 | ▲<br>+ 5.93%  | 0.10   |  |
| Spring | 5       | 12.6k     | 34.03 | ▲<br>+ 4.58%  | 0.07         | 223.8k | 36.39 | ▲<br>+ 7.18%  | 0.11   |  |
|        | 6       | 11.4k     | 32.64 | ▲<br>+ 6.90%  | 0.12         | 243.1k | 34.61 | ▲<br>+ 7.98%  | 0.14   |  |
|        | 7       | 11.2k     | 36.84 | ▲<br>+ 6.64%  | 0.11         | 201.5k | 35.84 | ▲<br>+ 6.29%  | 0.09   |  |
|        | 8       | 10.7k     | 33.33 | ▲<br>+ 3.09%  | 0.07         | 193.0k | 35.40 | ▲<br>+ 6.92%  | 0.11   |  |
|        | 9       | 10.3k     | 39.29 | ▲<br>+ 7.18%  | 0.11         | 194.7k | 42.37 | ▲<br>+ 9.55%  | 0.15   |  |
|        | 10      | 10.1k     | 32.50 | ▲<br>+ 6.74%  | 0.11         | 230.8k | 36.69 | ▲<br>+ 11.82% | 0.17   |  |

### Summary of Findings

Personalization is effective across different model sizes (60M, 750M and 7B parameters), and model architectures (T5 and Llama-based). Even Code Llama that likely saw code from the two subject organizations at training time benefitted of further specialized fine-tuning.

### <span id="page-23-1"></span>3.5 Goal 4: Investigating the Cost-Performance Trade-Off

As explained in Section [2.4.3,](#page-11-1) we also run an additional analysis aimed at understanding the cost-effectiveness of the personalized fine-tuning. Indeed, the personalized fine-tuning implies a training cost that the company would not have by just downloading a larger code-completion model already trained for such a task, and maybe exhibiting even better performance than the smaller, personalized model. For the reasons detailed in Section [2.4.3,](#page-11-1) we perform this analysis between the generic T5 model (i.e., B ), as represenattive of a general-purpose model that a company could download and use out of the box, and the personalized organization-specific T5 models.

We start by comparing the performance of both models for the top-10 developers of both organizations. Table [12](#page-24-0) shows the results. As it can be seen, the performance of the two models is comparable on the top-10 developers of both organizations. Indeed, when it comes to Apache, there is a statistically significant difference in EM predictions for five out of 10 developers, three times in favor of T5 and two in favor of T5 . As per Spring, the two models are basically equivalent (i.e., no statistically significant difference) for all developers. Overall, we can conclude that a model fine-tuned on organization-specific data can be as effective as a generic model that is over 10 times larger (60M vs 750M parameters).

In addition to the performance dimension of the comparison, we also aim to understand whether the cost of training a smaller personalized model is justified. Indeed, while the "generic" T5 (as well as any other already trained Manuscript submitted to ACM

<span id="page-24-0"></span>Why Personalizing Deep Learning-Based Code Completion Tools Matters 25

|        | Dev. ID | T5𝑙𝑎𝑟𝑔𝑒 | T5𝑠𝑚𝑎𝑙𝑙<br>organization |      |               |      |
|--------|---------|---------|-------------------------|------|---------------|------|
|        |         | EM %    | N°                      | EM % | Δ             | OR   |
| Apache | 1       | 52.8    | 888.0k                  | 61.8 | ▲<br>+ 9.00%  | 3.81 |
|        | 2       | 37.4    | 556.0k                  | 37.0 | ▼<br>- 0.40%  | 0.94 |
|        | 3       | 30.6    | 830.8k                  | 28.2 | ▼<br>- 2.40%  | 0.56 |
|        | 4       | 42.6    | 747.3k                  | 44.2 | ▲<br>+ 1.60%  | 1.38 |
|        | 5       | 29.0    | 540.5k                  | 24.0 | ▼<br>- 5.00%  | 0.42 |
|        | 6       | 39.0    | 791.4k                  | 37.2 | ▼<br>- 1.80%  | 0.67 |
|        | 7       | 47.4    | 524.8k                  | 70.0 | ▲<br>+ 22.60% | 6.95 |
|        | 8       | 34.0    | 850.5k                  | 32.2 | ▼<br>- 1.80%  | 0.68 |
|        | 9       | 41.8    | 580.9k                  | 48.4 | ▲<br>+ 6.60%  | 2.14 |
|        | 10      | 41.6    | 146.3k                  | 33.6 | ▼<br>- 8.00%  | 0.30 |
| Spring | 1       | 27.4    | 228.6k                  | 27.4 | 0.00%         | 1.00 |
|        | 2       | 24.8    | 188.0k                  | 26.0 | ▲<br>+ 1.20%  | 1.35 |
|        | 3       | 21.0    | 222.0k                  | 21.0 | 0.00%         | 1.00 |
|        | 4       | 19.0    | 226.5k                  | 19.4 | ▲<br>+ 0.40%  | 1.12 |
|        | 5       | 28.4    | 223.8k                  | 28.2 | ▼<br>- 0.20%  | 0.96 |
|        | 6       | 24.0    | 243.1k                  | 25.6 | ▲<br>+ 1.60%  | 1.38 |
|        | 7       | 26.0    | 201.5k                  | 27.8 | ▲<br>+ 1.80%  | 1.56 |
|        | 8       | 21.6    | 193.0k                  | 22.2 | ▲<br>+ 0.60%  | 1.13 |
|        | 9       | 28.6    | 194.7k                  | 26.4 | ▼<br>- 2.20%  | 0.70 |
|        | 10      | 21.6    | 230.8k                  | 23.8 | ▲<br>+ 2.20%  | 1.44 |

Table 12. Exact Match (EM) predictions of the base T5 vs T5 organization-specific models.

code model) could be just downloaded and used out of the box without any cost, the personalized T5 requires a fine-tuning which has a cost. However, we expect the T5 to have a higher "inference cost" (i.e., the cost of generating one prediction is higher). Section [2.4.3](#page-11-1) details how we computed the training and inference costs for the models. Remember that for the personalized T5 , we consider the training cost of both the cheapest (146.3k training instances) and the most expensive (888k training instances) organization-specific T5 from our study as a sort of lower- and upper-bounds.

Fig. [4](#page-25-1) shows on the axis the GPU renting cost for all three models (cheapest and most expensive organizationspecific T5 and the generic T5 ) given a different number of performed inferences ( axis). When no inferences are performed, T5 costs, in our simulation, 0\$ since we are assuming this is a generic model that the company downloaded and used out of the box. The T5 models, instead, bring with them the training cost (from a minimum of 0.75\$ to a maximum of 4.53\$). As we can see, there is a breakeven point after at least 44,948 and at most 272,824 inferences (best- and worst-case scenario). This leads to the following question: In how much time do the developers of an organization reach this number of code completion inferences? From an internal study at Microsoft [\[63\]](#page-31-7), we know that the average number of weekly recommendations that Copilot triggers to a single developer is 1,150. This means that if we consider a software company employing 10 developers, the breakeven point will be reached after four (best-case) to 24 (worst-case) weeks. With 40 developers, this goes down to 1-6 weeks.

### Summary of Findings

Thanks to a personalized fine-tuning, a company could deploy a ∼10× smaller model being equivalent in terms of code completion performance to the larger model. In terms of costs, the breakeven point is reached in few weeks (depending on the number of developers employed and the size of the used fine-tuning dataset).

<span id="page-25-1"></span>![](_page_25_Figure_1.jpeg)

Fig. 4. Cost-effectiveness analysis: Generic T5 vs organization-specific T5 .

### <span id="page-25-0"></span>4 SUMMARY OF MAIN FINDINGS

We summarize in the following the main findings output of our study, discussing their implications for researchers and software companies.

- (1) The boost in performance obtained by developer-specific models is often not sufficient to justify the additional effort of collecting the needed training data and run the fine-tuning (Goal 1). The main issue with a developerspecific fine-tuning is the lack of training data for most of developers. This has been observed even on a large organization such as Apache, for which hundreds of long-lived repositories were mined. Thus, we expect the lack of developer-specific data to be a show-stopper for most companies. However, our analysis on the impact of the training data size from Section [3.3](#page-17-0) also showed that, given a fixed amount of training data—generic, organization-specific, or developer-specific—there is a clear ranking in their effectiveness: the more specific the training data, the better the provided boost in performance, with the developer-specific ones being the most "precious". Basically, assuming the possibility to increase the size of the developer-specific training sets, such a personalized fine-tuning could be even more successful than the organization-specific one. Researchers could look into strategies such as data augmentation to address this limitation. On top of this, in our study we did not look into the performance provided by a combination of an organization-specific fine-tuning followed by a developer-specific fine-tuning. Also this strategy could bring benefits that we did not investigate.
- (2) An organization-specific fine-tuning should be the obvious choice for most companies interested in deploying an in-house code completion model (Goal 1). As explained, our analyses showed that this is due to the much higher number of training instances that can be collected at "organization-level". While the training cost is much higher than the one of the developer-specific dataset, a single fine-tuning would be required in a real scenario, while the developer-specific fine-tuning requires the training of a different model for each developer. Also, it is more convenient to deploy and maintain a single model.
- (3) The increase in performance observed with both specializations is not simply due to a higher number of training instances as compared to the baselines (Goal 2). Indeed, by further fine-tuning the baselines on generic data (and not on organization/developer-specific data) we did not observe an increase in performance comparable to the one Manuscript submitted to ACM

provided by the two specializations—see Section [3.3.](#page-17-0) This result stresses the key role played by the specificity of training data, and calls for additional investigation pertaining other code-related tasks (e.g., automated bug-fixing, code review).

- (4) The increase in performance ensured by personalization can be generalized to models having a different architecture and size (Goal 3). Indeed, all models we experimented with (T5 and Code Llama) benefitted from major performance improvements, independently from their size. This is a major finding of our study, since we can conjecture that even the code completion performance of very large models could be further boosted via personalization. Also, the inclusion of Code Llama in our experiments demonstrated that personalization can also work in scenarios in which code from the target organization was likely already seen at pre-training time.
- (5) Fine-tuning organization-specific DL models can be cost-effective (Goal 4). Indeed, we show that thanks to a personalized fine-tuning, DL models can achieve code completion performance on par with those of models being ∼10× larger (e.g., an organization-specific T5 achieves the same performance of a "generic" T5 model). The lower inference costs of smaller models will allow the companies to save money in the long run, since only a few weeks are needed to reach a breakeven point and amortize the training cost, depending on the number of developers employed in the company—see detailed analysis in Section [3.5.](#page-23-1)

### <span id="page-26-0"></span>5 THREATS TO VALIDITY

Construct validity. One threat is related to how we assess the code completion performance. While an EM prediction is likely to be useful for developers, it is difficult to speculate about non-EM predictions. The latter may be valuable while still being different from the expected target (e.g., the recommended code is different but semantically equivalent). We partially address this threat by also employing the CrystalBLEU as an evaluation metric, to at least provide a measure of how far the prediction is from the target.

Internal validity. As a design choice, we adopted the original architecture and hyperparameters for all models subject of our study. This was due to the high number of models we had to train for our study (396), which would have further increased with hyperparameters tuning. However, since we compared the baseline and the personalized models when using the same exact configuration, we expect no major impact of this choice on our main findings.

Another concern may be related to the effectiveness of the trainings we performed, especially when looking at the models we trained from scratch (i.e., the T5 models). While it is difficult to make a fair comparison with other T5 models from the literature which have been trained on different datasets and evaluated on different test sets, one possible point of reference about the "expected" performance of T5 for code completion comes from the work by Ciniselli et al. [\[18\]](#page-29-6), in which the authors experiment the T5 in three different completion scenarios, namely token-masking (i.e., completing the last tokens of a statement, with capped to 10), construct-masking (i.e., predicting specific code constructs, such as the conditions of if statements), and block-masking (i.e., predicting up to two complete code statements). Our test sets feature completions masking up to 50 tokens, possibly spanning across multiple statements, thus being "similar" to their block-masking scenario. When using pre-training and single-task fine-tuning (i.e., the same training procedure we adopt), Ciniselli et al. achieved 27.2% of EM predictions in the block-masking scenario on Java code. On average, across the 136 developers considered in our study, our baseline T5 (no personalized fine-tuning) achieved 26.4% of EM predictions, thus being aligned with previous findings [\[18\]](#page-29-6). This provides some confidence about the correctness of the training procedure.

External validity. While we considered a fairly high number of developers for our study (136), we focused on two organizations and one programming language (Java). Also, we used T5 and Code Llama as representative DL models for code completion. Our findings may not generalize to other settings.

### <span id="page-27-0"></span>6 RELATED WORK

Several DL-based techniques have been proposed to improve the automation provided by code completion tools (see e.g., [\[18,](#page-29-6) [19,](#page-29-15) [36,](#page-30-16) [39,](#page-30-17) [47,](#page-30-18) [55\]](#page-31-8)). Differently from our work, these studies focus on training the model with "general" coding knowledge provided via large-scale datasets. Other recent studies propose alternative approaches by leveraging in-context learning abilities of large language models [\[9,](#page-29-18) [13,](#page-29-19) [62\]](#page-31-9). In this section, we mainly discuss studies centered on the customization of recommender systems for code generation tasks and empirical investigations looking at code recommender tools from other perspectives [\[18,](#page-29-6) [20,](#page-29-20) [31,](#page-30-19) [35,](#page-30-20) [37,](#page-30-21) [38,](#page-30-22) [40,](#page-30-23) [43,](#page-30-24) [45,](#page-30-3) [61,](#page-31-10) [64\]](#page-31-11), focusing on reported findings which may relate to the motivations and outcome of our study.

### 6.1 Personalized Source Code Recommendations

To the best of our knowledge, only few works in the literature targeted the personalization of code recommendations.

Saraiva et al. [\[53\]](#page-30-25) conducted a preliminary study on the performance of -gram language models on the Microsoft Office suite using three levels of personalization: application-specific, developer-specific, and time-specific. Their findings show that -gram models trained on a single project always perform better than a general model working on the entire Office source code or a specific developer corpus. Furthermore, they found that models built on specific time-based datasets do not lead to particular performance improvements. In this work, we applied a similar idea to DL-based code completion, being the state of the practice nowadays.

Allamanis et al. [\[10\]](#page-29-21) presented Naturalize, a framework recommending "natural" identifier names and formatting choices which have been learned from a given codebase, thus improving the stylistic consistency of the project. Our work embraces the basic idea proposed in this work, looking however at the impact of personalization on the code completion capabilities of DL models.

Ahmed and Devanbu et al. [\[8\]](#page-29-22) investigated the usage of few-shot learning for customizing code summarization tasks. The authors collected code and summary pairs from eight repositories [\[42\]](#page-30-26). Then, they evaluated the few-shot capabilities of the model when preceding each query with 10 examples of the same project. They found that using project-specific examples instead of cross-project instances can improve the inference accuracy of the model.

The most related work to our study is the one recently presented by Zlotchevski et al. [\[65\]](#page-31-12), who studied whether the automated generation of tests can be improved by further fine-tuning a DL model on a specific software repository. Given a DL model already fine-tuned to generate unit tests, the authors further trained it on code coming from a specific code repository, reporting an improved accuracy of the suggestions. In this work, we focus on the more generic task of DL-based code completion, which is used by millions of developers and thousands of companies [\[7\]](#page-29-23) via tools such as Copilot. Also, we look at different levels of personalization, related to a whole organization and a single developer, which have not been previously explored in the literature.

### 6.2 Empirical Studies on Code Recommender Systems

Mărăs, oiu et al. [\[43\]](#page-30-24) studied how developers use code completion tools, showing that they make extensive use of these tools but often discard the provided suggestions, especially when they feature APIs they are not familiar to. This helps motivating the need for personalized code completion.

Why Personalizing Deep Learning-Based Code Completion Tools Matters 29

Hellendoorn et al. [\[31\]](#page-30-19) reported the inadequacy of artificial benchmarks in evaluating code completion tools, since these do not reflect the complexity of real-world completions. Similar findings were reported by Liu et al. [\[40\]](#page-30-23) for the task of requirements implementation (i.e., generating code starting from a natural language description). These findings are among the reasons why our test sets feature code completions derived by real code changes implemented by software developers.

Ciniselli et al. [\[18\]](#page-29-6) showed that T5 can accurately recommend code completions spanning across a single statement (∼69% of accuracy) and still achieve good results when dealing with the completion of entire statements (∼29%). This motivated our selection of the subject DL model.

Other studies focused on the effectiveness of the support provided by code completion tools to developers [\[35,](#page-30-20) [45,](#page-30-3) [61\]](#page-31-10), documenting limitations of these tools, including: the lack of improvement in developers' productivity [\[61\]](#page-31-10), the presence of low quality recommendations [\[35\]](#page-30-20), and issues related to their robustness [\[45\]](#page-30-3). These works point to the need for additional research aimed at improving code recommenders.

### <span id="page-28-0"></span>7 CONCLUSION AND FUTURE WORK

In this work, we investigate how personalizing DL-based code completion tools can help in boosting their performance. We show that, by fine-tuning a generic code completion model on personalized instances (i.e., completions from the same developer/organization), it can achieve significantly better performance, also when compared to a model fine-tuned on the same number of non-personalized instances. Our results hold along four dimensions: (i) different levels of personalization (organization-specific and developer-specific data), with organization-specific personalization being, however, more effective thanks to the availability of more training data; (ii) different developers (136) from two different organizations (Apache and Spring); (iii) different sizes of the training dataset used to personalize the model (between 1k and 908.1k instances); and (iv) different model sizes and architecture (60M and 750M T5 models and 7B Code Llama).

Our findings show that most developers within an organization can benefit from personalized recommendations, even when no developer-specific data is available (e.g., using the organization-specific model for developers new to the organization). Furthermore, companies providing industry-ready code completion tools (e.g., GitHub Copilot [\[3\]](#page-29-24)) may find new business opportunities by offering personalized models to their customers, while smaller-scale models deployed in-house, when personalized, may be competitive and closer to what offered by larger models.

In future work, we plan to: (i) study the impact of various hyperparameters (e.g., learning rate) on the personalization process; and (ii) investigate new approaches to enhance personalization such as auto-regressive models, prompting, and reinforcement learning. Lastly, we also plan to investigate online approaches for regularly training these models on relevant and up-to-date code, and to cover further completion tasks (e.g., modifying a single token instead of entire code lines or blocks). All code and data used in our study is publicly available [\[5\]](#page-29-25).

### ACKNOWLEDGMENTS

We are deeply grateful to the [I3US Institute](https://i3us.us.es/) and the [SCORE Lab](https://score.us.es/) at the University of Seville for providing us access to their HPC cluster, on which the experiments were run, and without which this research would not be possible. We acknowledge the financial support of the Swiss National Science Foundation for the PARSED project (SNF Project No. 219294).

### REFERENCES

- <span id="page-29-9"></span>[1] [n. d.]. Apache Commons BeanUtils. [https://github.com/apache/commons-beanutils/.](https://github.com/apache/commons-beanutils/) Accessed: 2024-03-05.
- <span id="page-29-11"></span>[2] [n. d.]. CodeParrot GitHub Code dataset. [https://huggingface.co/datasets/codeparrot/github-code.](https://huggingface.co/datasets/codeparrot/github-code) Accessed: 2024-02-08.
- <span id="page-29-24"></span>[3] [n. d.]. GitHub Copilot – Your AI pair programmer. [https://github.com/features/copilot/.](https://github.com/features/copilot/) Accessed: 2024-03-10.
- <span id="page-29-10"></span>[4] [n. d.]. javalang - PyPI. [https://pypi.org/project/javalang/.](https://pypi.org/project/javalang/) Accessed: 2024-02-08.
- <span id="page-29-25"></span>[5] [n. d.]. Replication Package. [https://doi.org/10.5281/zenodo.10817220.](https://doi.org/10.5281/zenodo.10817220)
- <span id="page-29-7"></span>[6] [n. d.]. T5v1.1. [https://huggingface.co/docs/transformers/en/model\\_doc/t5v1.1.](https://huggingface.co/docs/transformers/en/model_doc/t5v1.1) Accessed: 2024-02-08.
- <span id="page-29-23"></span>[7] [n.d.]. Microsoft Fiscal Year 2024 Second Quarter Earnings Conference Call. [https://www.microsoft.com/en-us/investor/events/fy-2024/earnings-fy-](https://www.microsoft.com/en-us/investor/events/fy-2024/earnings-fy-2024-q2.aspx)[2024-q2.aspx.](https://www.microsoft.com/en-us/investor/events/fy-2024/earnings-fy-2024-q2.aspx) Accessed: 2024-02-02.
- <span id="page-29-22"></span>[8] Toufique Ahmed and Premkumar Devanbu. 2022. Few-shot training LLMs for project-specific code-summarization. In Proceedings of the 37th IEEE/ACM International Conference on Automated Software Engineering. 1–5.
- <span id="page-29-18"></span>[9] Toufique Ahmed, Kunal Suresh Pai, Premkumar Devanbu, and Earl Barr. 2024. Automatic semantic augmentation of language model prompts (for code summarization). In Proceedings of the IEEE/ACM 46th International Conference on Software Engineering. 1–13.
- <span id="page-29-21"></span>[10] Miltiadis Allamanis, Earl T. Barr, Christian Bird, and Charles Sutton. 2014. Learning natural coding conventions. In 22nd ACM/SIGSOFT International Symposium on Foundations of Software Engineering, FSE. 281–293.
- <span id="page-29-13"></span>[11] Uri Alon, Roy Sadaka, Omer Levy, and Eran Yahav. 2020. Structural language models of code. In International Conference on Machine Learning, ICML. 245–256.
- <span id="page-29-14"></span>[12] Muhammad Asaduzzaman, Chanchal K. Roy, Kevin A. Schneider, and Daqing Hou. 2014. Context-Sensitive Code Completion Tool for Better API Usability. In 30th IEEE International Conference on Software Maintenance and Evolution ICSME. 621–624.
- <span id="page-29-19"></span>[13] Ramakrishna Bairi, Atharv Sonwane, Aditya Kanade, Arun Iyer, Suresh Parthasarathy, Sriram Rajamani, B Ashok, Shashank Shet, et al. 2023. Codeplan: Repository-level coding using llms and planning. arXiv preprint arXiv:2309.12499 (2023).
- <span id="page-29-5"></span>[14] Berkay Berabi, Jingxuan He, Veselin Raychev, and Martin Vechev. 2021. TFix: Learning to Fix Coding Errors with a Text-to-Text Transformer. In Proceedings of the 38th International Conference on Machine Learning (Proceedings of Machine Learning Research, Vol. 139), Marina Meila and Tong Zhang (Eds.). PMLR, 780–791.
- <span id="page-29-0"></span>[15] Marcel Bruch, Martin Monperrus, and Mira Mezini. 2009. Learning from examples to improve code completion systems. In 7th ACM Joint Meeting of the European Software Engineering Conference and the ACM/SIGSOFT International Symposium on Foundations of Software Engineering ESEC-FSE. 213–222.
- <span id="page-29-8"></span>[16] Federico Cassano, John Gouwar, Francesca Lucchetti, Claire Schlesinger, Anders Freeman, Carolyn Jane Anderson, Molly Q Feldman, Michael Greenberg, Abhinav Jangda, and Arjun Guha. 2024. Knowledge transfer from high-resource to low-resource programming languages for code llms. Proceedings of the ACM on Programming Languages 8, OOPSLA2 (2024), 677–708.
- <span id="page-29-2"></span>[17] Mark Chen, Jerry Tworek, Heewoo Jun, Qiming Yuan, Henrique Ponde de Oliveira Pinto, Jared Kaplan, Harri Edwards, Yuri Burda, Nicholas Joseph, Greg Brockman, et al. 2021. Evaluating large language models trained on code. arXiv preprint arXiv:2107.03374 (2021).
- <span id="page-29-6"></span>[18] Matteo Ciniselli, Nathan Cooper, Luca Pascarella, Antonio Mastropaolo, Emad Aghajani, Denys Poshyvanyk, Massimiliano Di Penta, and Gabriele Bavota. 2021. An Empirical Study on the Usage of Transformer Models for Code Completion. IEEE Transactions on Software Engineering, TSE abs/2108.01585, 01 (2021), 1–1.
- <span id="page-29-15"></span>[19] Matteo Ciniselli, Nathan Cooper, Luca Pascarella, Denys Poshyvanyk, Massimiliano Di Penta, and Gabriele Bavota. 2021. An Empirical Study on the Usage of BERT Models for Code Completion. In 18th IEEE/ACM International Conference on Mining Software Repositories, MSR 2021. 108–119.
- <span id="page-29-20"></span>[20] Matteo Ciniselli, Luca Pascarella, and Gabriele Bavota. 2022. To What Extent do Deep Learning-based Code Recommenders Generate Predictions by Cloning Code from the Training Set?. In 19th IEEE/ACM International Conference on Mining Software Repositories, MSR. 167–178.
- <span id="page-29-17"></span>[21] Ozren Dabic, Emad Aghajani, and Gabriele Bavota. 2021. Sampling Projects in GitHub for MSR Studies. In 18th IEEE/ACM International Conference on Mining Software Repositories, MSR. 560–564.
- <span id="page-29-12"></span>[22] Jacob Devlin, Ming-Wei Chang, Kenton Lee, and Kristina Toutanova. 2019. BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding. In Conference of the North American Chapter of the Association for Computational Linguistics: Human Language Technologies, NAACL-HLT. 4171–4186.
- <span id="page-29-16"></span>[23] Aryaz Eghbali and Michael Pradel. 2022. CrystalBLEU: Precisely and Efficiently Measuring the Similarity of Code. In Proceedings of the 37th IEEE/ACM International Conference on Automated Software Engineering. 1–12.
- <span id="page-29-1"></span>[24] Neil A. Ernst and Gabriele Bavota. 2022. AI-Driven Development Is Here: Should You Worry? IEEE Softw. 39, 2 (2022), 106–110. [https:](https://doi.org/10.1109/MS.2021.3133805) [//doi.org/10.1109/MS.2021.3133805](https://doi.org/10.1109/MS.2021.3133805)
- <span id="page-29-3"></span>[25] Johannes Eschbach-Dymanus, Frank Essenberger, Bianka Buschbeck, and Miriam Exel. 2024. Exploring the Effectiveness of LLM Domain Adaptation for Business IT Machine Translation. In Proceedings of the 25th Annual Conference of the European Association for Machine Translation (Volume 1), Carolina Scarton, Charlotte Prescott, Chris Bayliss, Chris Oakley, Joanna Wright, Stuart Wrigley, Xingyi Song, Edward Gow-Smith, Rachel Bawden, Víctor M Sánchez-Cartagena, Patrick Cadwell, Ekaterina Lapshinova-Koltunski, Vera Cabarrão, Konstantinos Chatzitheodorou, Mary Nurminen, Diptesh Kanojia, and Helena Moniz (Eds.). 610–622.
- <span id="page-29-4"></span>[26] Zhangyin Feng, Daya Guo, Duyu Tang, Nan Duan, Xiaocheng Feng, Ming Gong, Linjun Shou, Bing Qin, Ting Liu, Daxin Jiang, et al. 2020. Codebert: A pre-trained model for programming and natural languages. arXiv preprint arXiv:2002.08155 (2020).

## Why Personalizing Deep Learning-Based Code Completion Tools Matters 31

- <span id="page-30-6"></span>[27] Isha Ganguli, Rajat Subhra Bhowmick, Shivam Biswas, and Jaya Sil. 2021. Empirical Auto-Evaluation of Python Code for Performance Analysis of Transformer Network Using T5 Architecture. In 2021 8th International Conference on Smart Computing and Communications (ICSCC). 75–79. <https://doi.org/10.1109/ICSCC51209.2021.9528123>
- <span id="page-30-11"></span>[28] Christoph Gote and Christian Zingg. 2021. gambit – An Open Source Name Disambiguation Tool for Version Control Systems. In 2021 IEEE/ACM 18th International Conference on Mining Software Repositories (MSR). 80–84. <https://doi.org/10.1109/MSR52588.2021.00021>
- <span id="page-30-15"></span>[29] Robert J. Grissom and John J. Kim. 2005. Effect sizes for research: A broad practical approach (2nd edition ed.). Lawrence Earlbaum Associates.
- <span id="page-30-12"></span>[30] Vincent J. Hellendoorn and Premkumar Devanbu. 2017. Are Deep Neural Networks the Best Choice for Modeling Source Code?. In 11th ACM/SIGSOFT Joint Meeting on Foundations of Software Engineering ESEC-FSE. 763?773.
- <span id="page-30-19"></span>[31] Vincent J. Hellendoorn, Sebastian Proksch, Harald C. Gall, and Alberto Bacchelli. 2019. When code completion fails: a case study on real-world completions. In 41st IEEE/ACM International Conference on Software Engineering, ICSE. 960–970.
- <span id="page-30-2"></span>[32] Abram Hindle, Earl T. Barr, Zhendong Su, Mark Gabel, and Premkumar T. Devanbu. 2012. On the naturalness of software. In 34th IEEE/ACM International Conference on Software Engineering, ICSE. 837–847.
- <span id="page-30-10"></span>[33] Edward J Hu, Yelong Shen, Phillip Wallis, Zeyuan Allen-Zhu, Yuanzhi Li, Shean Wang, Lu Wang, and Weizhu Chen. 2022. LoRA: Low-Rank Adaptation of Large Language Models. In International Conference on Learning Representations. <https://openreview.net/forum?id=nZeVKeeFYf9>
- <span id="page-30-9"></span>[34] Kai Huang, Jian Zhang, Xiangxin Meng, and Yang Liu. 2024. Template-Guided Program Repair in the Era of Large Language Models. In 2025 IEEE/ACM 47th International Conference on Software Engineering (ICSE). IEEE Computer Society, 367–379.
- <span id="page-30-20"></span>[35] Saki Imai. 2022. Is github copilot a substitute for human pair-programming? an empirical study. In Proceedings of the ACM/IEEE 44th International Conference on Software Engineering: Companion Proceedings. 319–321.
- <span id="page-30-16"></span>[36] Maliheh Izadi, Roberta Gismondi, and Georgios Gousios. 2022. CodeFill: Multi-token Code Completion by Jointly learning from Structure and Naming Sequences. In 44th IEEE/ACM International Conference on Software Engineering, ICSE. 401–412.
- <span id="page-30-21"></span>[37] Maliheh Izadi, Jonathan Katzy, Tim Van Dam, Marc Otten, Razvan Mihai Popescu, and Arie Van Deursen. 2024. Language models for code completion: A practical evaluation. In Proceedings of the IEEE/ACM 46th International Conference on Software Engineering. 1–13.
- <span id="page-30-22"></span>[38] Xianhao Jin and Francisco Servant. 2018. The hidden cost of code completion: Understanding the impact of the recommendation-list length on its efficiency. In 15th IEEE/ACM International Conference on Mining Software Repositories, MSR. 70–73.
- <span id="page-30-17"></span>[39] Fang Liu, Ge Li, Yunfei Zhao, and Zhi Jin. 2020. Multi-task Learning based Pre-trained Language Model for Code Completion. In 35th IEEE/ACM International Conference on Automated Software Engineering, ASE. 473–485.
- <span id="page-30-23"></span>[40] Hui Liu, Mingzhu Shen, Jiaqi Zhu, Nan Niu, Ge Li, and Lu Zhang. 2020. Deep learning based program generation from requirements text: Are we there yet? IEEE Transactions on Software Engineering 48, 4 (2020), 1268–1289.
- <span id="page-30-8"></span>[41] Ilya Loshchilov and Frank Hutter. 2019. Decoupled Weight Decay Regularization. In 7th International Conference on Learning Representations, ICLR.
- <span id="page-30-26"></span>[42] Shuai Lu, Daya Guo, Shuo Ren, Junjie Huang, Alexey Svyatkovskiy, Ambrosio Blanco, Colin B. Clement, Dawn Drain, Daxin Jiang, Duyu Tang, Ge Li, Lidong Zhou, Linjun Shou, Long Zhou, Michele Tufano, Ming Gong, Ming Zhou, Nan Duan, Neel Sundaresan, Shao Kun Deng, Shengyu Fu, and Shujie Liu. 2021. CodeXGLUE: A Machine Learning Benchmark Dataset for Code Understanding and Generation. In 35th Neural Information Processing Systems Track on Datasets and Benchmarks 1, NeurIPS Datasets and Benchmarks.
- <span id="page-30-24"></span>[43] Mariana Marasoiu, Luke Church, and Alan F. Blackwell. 2015. An empirical investigation of code completion usage by professional software developers. In 26th Annual Workshop of the Psychology of Programming Interest Group, PPIG. 14.
- <span id="page-30-7"></span>[44] Antonio Mastropaolo, Nathan Cooper, David Nader Palacio, Simone Scalabrino, Denys Poshyvanyk, Rocco Oliveto, and Gabriele Bavota. 2022. Using Transfer Learning for Code-Related Tasks. IEEE Transactions on Software Engineering, TSE (2022), 1–20.
- <span id="page-30-3"></span>[45] Antonio Mastropaolo, Luca Pascarella, Emanuela Guglielmi, Matteo Ciniselli, Simone Scalabrino, Rocco Oliveto, and Gabriele Bavota. 2023. On the Robustness of Code Generation Techniques: An Empirical Study on GitHub Copilot. In 45th IEEE/ACM International Conference on Software Engineering, ICSE 2023, Melbourne, Australia, May 14-20, 2023. IEEE, 2149–2160.
- <span id="page-30-14"></span>[46] Quinn McNemar. 1947. Note on the sampling error of the difference between correlated proportions or percentages. Psychometrika 12, 2 (1947), 153–157.
- <span id="page-30-18"></span>[47] Phuong T. Nguyen, Juri Di Rocco, Claudio Di Sipio, Davide Di Ruscio, and Massimiliano Di Penta. 2022. Recommending API Function Calls and Code Snippets to Support Software Development. IEEE Trans. Software Eng. 48, 7 (2022), 2417–2438.
- <span id="page-30-13"></span>[48] Kishore Papineni, Salim Roukos, Todd Ward, and Wei-Jing Zhu. 2002. BLEU: A Method for Automatic Evaluation of Machine Translation. In 40th Annual Meeting on Association for Computational Linguistics, ACL. 311–318.
- <span id="page-30-1"></span>[49] Sida Peng, Eirini Kalliamvakou, Peter Cihon, and Mert Demirer. 2023. The impact of AI on developer productivity: Evidence from GitHub Copilot. arXiv preprint arXiv:2302.06590 (2023).
- <span id="page-30-5"></span>[50] Colin Raffel, Noam Shazeer, Adam Roberts, Katherine Lee, Sharan Narang, Michael Matena, Yanqi Zhou, Wei Li, and Peter J. Liu. 2020. Exploring the Limits of Transfer Learning with a Unified Text-to-Text Transformer. Journal of Machine Learning Research 21, 140 (2020), 1–67. [http:](http://jmlr.org/papers/v21/20-074.html) [//jmlr.org/papers/v21/20-074.html](http://jmlr.org/papers/v21/20-074.html)
- <span id="page-30-0"></span>[51] Romain Robbes and Michele Lanza. 2010. Improving Code Completion with Program History. Automated Software Engineering 17, 2 (2010), 181–212.
- <span id="page-30-4"></span>[52] Baptiste Roziere, Jonas Gehring, Fabian Gloeckle, Sten Sootla, Itai Gat, Xiaoqing Ellen Tan, Yossi Adi, Jingyu Liu, Tal Remez, Jérémy Rapin, et al. 2023. Code llama: Open foundation models for code. arXiv preprint arXiv:2308.12950 (2023).
- <span id="page-30-25"></span>[53] Juliana Saraiva, Christian Bird, and Thomas Zimmermann. 2015. Products, developers, and milestones: how should I build my N-Gram language model. In Proceedings of the 2015 10th Joint Meeting on Foundations of Software Engineering. 998–1001.
- <span id="page-31-3"></span><span id="page-31-0"></span>[54] Weisong Sun, Yun Miao, Yuekang Li, Hongyu Zhang, Chunrong Fang, Yi Liu, Gelei Deng, Yang Liu, and Zhenyu Chen. 2024. Source Code Summarization in the Era of Large Language Models. In 2025 IEEE/ACM 47th International Conference on Software Engineering (ICSE). IEEE Computer Society, 419–431.
- <span id="page-31-8"></span>[55] Alexey Svyatkovskiy, Sebastian Lee, Anna Hadjitofi, Maik Riechert, Juliana Vicente Franco, and Miltiadis Allamanis. 2021. Fast and Memory-Efficient Neural Code Completion. In 18th IEEE/ACM International Conference on Mining Software Repositories, MSR. 329–340.
- <span id="page-31-5"></span>[56] Hugo Touvron, Louis Martin, Kevin Stone, Peter Albert, Amjad Almahairi, Yasmine Babaei, Nikolay Bashlykov, Soumya Batra, Prajjwal Bhargava, Shruti Bhosale, et al. 2023. Llama 2: Open foundation and fine-tuned chat models. arXiv preprint arXiv:2307.09288 (2023).
- <span id="page-31-2"></span>[57] Rosalia Tufano, Simone Masiero, Antonio Mastropaolo, Luca Pascarella, Denys Poshyvanyk, and Gabriele Bavota. 2022. Using Pre-Trained Models to Boost Code Review Automation. In 44th IEEE/ACM International Conference on Software Engineering, ICSE. 2291–2302.
- <span id="page-31-1"></span>[58] Yue Wang, Weishi Wang, Shafiq Joty, and Steven CH Hoi. 2021. Codet5: Identifier-aware unified pre-trained encoder-decoder models for code understanding and generation. arXiv preprint arXiv:2109.00859 (2021).
- <span id="page-31-4"></span>[59] Martin Weyssow, Xin Zhou, Kisub Kim, David Lo, and Houari Sahraoui. 2023. Exploring parameter-efficient fine-tuning techniques for code generation with large language models. arXiv preprint arXiv:2308.10462 (2023).
- <span id="page-31-6"></span>[60] Frank Wilcoxon. 1945. Individual Comparisons by Ranking Methods. Biometrics Bulletin 1, 6 (1945), 80–83.
- <span id="page-31-10"></span>[61] Frank F. Xu, Bogdan Vasilescu, and Graham Neubig. 2022. In-IDE Code Generation from Natural Language: Promise and Challenges. ACM Trans. Softw. Eng. Methodol. 31, 2 (2022), 29:1–29:47.
- <span id="page-31-9"></span>[62] Fengji Zhang, Bei Chen, Yue Zhang, Jin Liu, Daoguang Zan, Yi Mao, Jian-Guang Lou, and Weizhu Chen. 2023. RepoCoder: Repository-Level Code Completion Through Iterative Retrieval and Generation. arXiv preprint arXiv:2303.12570 (2023).
- <span id="page-31-7"></span>[63] Albert Ziegler. 2022. GitHub Copilot research recitation. [https://github.blog/ai-and-ml/github-copilot/github-copilot-research-recitation/.](https://github.blog/ai-and-ml/github-copilot/github-copilot-research-recitation/) Accessed: 2024-11-10.
- <span id="page-31-11"></span>[64] Albert Ziegler, Eirini Kalliamvakou, X. Alice Li, Andrew Rice, Devon Rifkin, Shawn Simister, Ganesh Sittampalam, and Edward Aftandilian. 2022. Productivity assessment of neural code completion. In International Symposium on Machine Programming. 21–29.
- <span id="page-31-12"></span>[65] Andrei Zlotchevski, Dawn Drain, Alexey Svyatkovskiy, Colin B. Clement, Neel Sundaresan, and Michele Tufano. 2022. Exploring and evaluating personalized models for code generation. In Proceedings of the 30th ACM Joint European Software Engineering Conference and Symposium on the Foundations of Software Engineering (ESEC/FSE 2022). 1500–1508.

revised DD MMMM YYYY; accepted DD MMMM YYYY