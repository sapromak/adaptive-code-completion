# Long Code Arena: a Set of Benchmarks for Long-Context Code Models

Egor Bogomolov1,<sup>2</sup> , Aleksandra Eliseeva<sup>1</sup> , Timur Galimzyanov<sup>1</sup> , Evgeniy Glukhov<sup>1</sup> , Anton Shapkin<sup>1</sup> , Maria Tigina<sup>1</sup> , Yaroslav Golubev<sup>1</sup> , Alexander Kovrigin<sup>1</sup> , Arie van Deursen<sup>2</sup> , Maliheh Izadi<sup>2</sup> , Timofey Bryksin<sup>1</sup> 1 JetBrains Research, <sup>2</sup>Delft University of Technology lca@jetbrains.com

# Abstract

Nowadays, the fields of code and natural language processing are evolving rapidly. In particular, models become better at processing long context windows — supported context sizes have increased by orders of magnitude over the last few years. However, there is a shortage of benchmarks for code processing that go beyond a single file of context, while the most popular ones are limited to a single method. With this work, we aim to close this gap by introducing Long Code Arena, a suite of six benchmarks for code processing tasks that require project-wide context. These tasks cover different aspects of code processing: library-based code generation, CI builds repair, project-level code completion, commit message generation, bug localization, and module summarization. For each task, we provide a manually verified dataset for testing, an evaluation suite, and open-source baseline solutions based on popular LLMs to showcase the usage of the dataset and to simplify adoption by other researchers. We publish the benchmark page on Hugging-Face Spaces with the leaderboard, links to HuggingFace Hub for all the datasets, and link to the GitHub repository with baselines: [https://huggingface.co/](https://huggingface.co/spaces/JetBrains-Research/long-code-arena) [spaces/JetBrains-Research/long-code-arena](https://huggingface.co/spaces/JetBrains-Research/long-code-arena).

# 1 Introduction

The Machine Learning for Software Engineering (ML4SE) domain has gained popularity over the recent years, with increasingly more powerful models for text and code processing becoming available. According to a recent survey [\[24\]](#page-9-0), the most common ML4SE tasks studied in the literature are code generation, code completion, code summarization, and program repair. Unfortunately, the majority of existing benchmarks for assessing ML4SE models have two major limitations: a short length of the available context and a limited resemblance of the practical use cases [\[22](#page-9-1), [31](#page-10-0)].

Two common trends in modern natural language processing (NLP) are retrieval-augmented generation [\[17](#page-9-2)] and utilization of long contexts [\[56\]](#page-11-0). Retrieval-augmented approaches [\[5](#page-8-0), [28\]](#page-9-3) can base their predictions on information from large corpora of data using various search techniques, while the development of new architectures [\[46](#page-10-1), [16,](#page-9-4) [19\]](#page-9-5) and techniques [\[11,](#page-8-1) [3](#page-8-2)] allows models to process tens of thousands or even millions of tokens. Both long-context and retrieval-augmented models can in theory utilize information from an entire software project. However, most existing ML4SE benchmarks operate with short code snippets — methods or at most files. For example, two most popular code generation datasets—HumanEval [\[6\]](#page-8-3) and MBPP [\[2\]](#page-8-4)—require models to comprehend fewer than 1,000 tokens and generate a short function, usually no more than 100 tokens long.

Researchers already do work on extending available context for ML4SE benchmarks. As an example, several recent works investigate code completion at the repository level [\[39,](#page-10-2) [63](#page-11-1)]. However, their usage of software data does not account for the iterative nature of software development: while

solving the code completion task in a single file, the benchmarks allow models to use the rest of the project without restrictions. At the same time, other parts of the project can be written after the studied file and utilize its contents, giving the model hints that will not be present in the practical use-case.

In this work, we present *Long Code Arena*, a suite of novel benchmarks for ML4SE models that cover six tasks: library-based code generation, CI builds repair, project-level code completion, commit message generation, bug localization, and module summarization. We design all the tasks and datasets in such a way that they require models to use information from a project module or the entire project to successfully complete the task. For all the tasks, samples used for evaluation are rigorously filtered and then manually verified to ensure the best possible data quality. The data for all the tasks comes from open-source repositories with permissive licenses. We also provide baseline solutions for all the tasks based on popular models, although this work does not aim at solving the tasks — baselines are provided solely to aid future research.

In the paper, we describe the data collection methodology for each task, describe the evaluation setup, and briefly discuss the implemented baselines. At the end of the paper, we also discuss related work and the drawbacks of the existing datasets. In the Supplementary materials, we thoroughly describe the structure of the datasets and provide a detailed description of the baselines. We open-source the implementations of baselines along with code for evaluation, they can be found on GitHub[1](#page-1-0) and serve as an example of using the collected datasets. You can access the leaderboard and links to all the datasets (published via HuggingFace Hub) in our HuggingFace Space.[2](#page-1-1)

# 2 Long Code Arena

Long Code Arena is a suite of six benchmarks that cover different aspects of code processing: generation, repair, completion, summarization, processing diffs. For each task, we gather an evaluation dataset of around a hundred to a thousand examples that requires models to operate with source code at the scale of a module or an entire repository. For most tasks, we focus on Python code due to its popularity and to manually verify the correctness of the samples. However, the collection methodology for all the tasks allows extending the benchmarks with more languages in the future.

All the datasets we collect in Long Code Arena are based on data from open-source GitHub repositories — source code, commit history, issues, as well as build data from GitHub Actions. First, we extract a common corpus of repositories for further processing. To do so, we get the list of repositories via GitHub Search [\[10\]](#page-8-5) that pass the following filters used in other works to ensure the quality of the data [\[30\]](#page-9-6): at least 1,000 commits, at least ten contributors, issues, and stars, at least 10,000 lines of code, not a fork, last commit after 01.06.2023, and a permissive license (we use the most popular permissive licenses [\[59](#page-11-2)] — MIT, Apache-2.0, BSD-3-Clause, and BSD-2-Clause). After the filtering, we are left with 4,343 repositories that we then download via GitHub API along with issues and pull requests data. For the CI builds repair task, we also retrieve GitHub Actions logs for some repositories, which we describe further. The only task that we base on the existing dataset is commit message generation, for which we find samples with large commits and long commit messages in the recent CommitChronicle dataset [\[13\]](#page-9-7).

After the initial data collection stage, we prepare evaluation datasets for each of the six tasks separately. For this, we apply further task-specific filters to the collected data, and then manually examine the samples to ensure their correctness. The following subsections contain in-detail descriptions of all the benchmarks.

### 2.1 Library-based Code Generation

Task description. The first task in our work is a novel library-based code generation task. Given a task description and access to the contents of a software library, the model should generate a single file that solves the task heavily utilizing methods from the given library. The problem is motivated by the need of programmers to write code that utilizes the present dependencies and in-project APIs rather than adding new dependencies and increasing project complexity.

<span id="page-1-0"></span><sup>1</sup>Long Code Arena baselines: <https://github.com/JetBrains-Research/lca-baselines>

<span id="page-1-1"></span><sup>2</sup>Long Code Arena leaderboard: [https://huggingface.co/spaces/JetBrains-Research/](https://huggingface.co/spaces/JetBrains-Research/long-code-arena) [long-code-arena](https://huggingface.co/spaces/JetBrains-Research/long-code-arena)

In contrast to library-based code generation, existing code generation benchmarks require models to produce self-sufficient code snippets, such as solutions to algorithmic problems [\[6](#page-8-3), [2,](#page-8-4) [23\]](#page-9-8), domainspecific code [\[36\]](#page-10-3), one-liners [\[62\]](#page-11-3), etc. Among the existing works, the setup of the library-based code generation task is similar to repository-level code completion benchmarks that evaluate API completion [\[39,](#page-10-2) [63\]](#page-11-1). Contrary to them, our benchmark requires models to generate an entire program based on an instruction in natural language instead of a single API call or a single line.

Collection methodology. To prepare the benchmark, we first extract usage examples from the Python projects that we collected by finding directories in the project roots that contain "examples" in their name. Such usage examples are provided by the library authors in order to show the capabilities and use cases of their libraries.

After collecting the examples, we filter them: (i) remove examples shorter than 100 or longer than 40,000 characters (excluding comments), (ii) remove examples that have fewer than 400 characters of comments in order to then write high-quality instruction for generation, (iii) remove examples that use fewer than ten API calls specific to the given library. To identify library-specific API calls, we extract names of all functions and classes defined in the mined Python projects and count as library-specific only the ones that appear in a single library. These filters result in 150 files (usage examples) from 62 libraries, with each file heavily relying on the APIs of the respective project.

To create instructions, we first run the selected 150 files through GPT-4 [\[1](#page-8-6)], prompting it to generate an instruction for generating the respective file. This leaves us with step-by-step instructions that the LLM should then follow to generate a script that utilizes the library at hand. Then, we manually fix each instruction in order to reduce hinting to specific library methods and ensure its correctness.

To build contexts for generation, benchmark users have access to contents of the libraries that include on average 254 Python files with 2.5M characters and 2,242 unique class and method names. The respective medians are 164 files, 1.4M characters, and 1,412 names.

Metrics. Following the previous work on metrics for assessing code generation quality [\[14\]](#page-9-9), we employ ChrF [\[47](#page-10-4)] to measure how similar the generated code is to the original human-written one. Additionally, to assess usage of the respective library, we measure *API Recall* calculated as the ratio of library-specific API calls (called functions, instantiated classes, used constants) made by the ground truth solution that also appear in the generated program.

Baselines. We evaluate six models: proprietary GPT-3.5-turbo and GPT-4 [\[1](#page-8-6)], and instructiontuned versions of open-source CodeLlama-7B, CodeLlama-70B [\[50](#page-11-4)], Mistral-7B [\[26](#page-9-10)], and Mixtral-8x7B [\[27\]](#page-9-11). In the first setup, we assess the models' ability to generate code based solely on instruction, without access to the library. In the second setup, we accompany the instruction with 20 method and class names most similar to the instruction according to BM-25 [\[48\]](#page-10-5). In both setups, GPT-4 shows the best quality with the API Recall of 37%, while open-source models without library context achieve the API Recall of 7–11%. BM-25 retrieval allows to improve the API Recall for all models except for GPT-4 by 3–6%, leaving a huge space for further improvement.

# 2.2 CI Builds Repair

Task description. The second task in our benchmark suite is fixing failing CI builds. This task asks models to generate a patch that fixes a real-life issue in a CI setup. The minimal set of data for the task consists of a repository snapshot at the commit that caused the failure of the workflow (*failed commit* hereafter) and the logs of the failed step. The task can also be performed in a simplified *oracle* setup by prompting a model with a list of files and code blocks in them to change. In this case, the code blocks come from the ground-truth fixing diff provided in the dataset. An important feature of this task is run-based evaluation: we utilize GitHub Actions [\[18](#page-9-12)] to run the generated fixes and assess their correctness.

Collection methodology. To collect the data, we iterate over the 100 largest downloaded Python repositories and get a full list of action runs in each repo started in the last 90 days, as older GitHub Actions logs are not available. The downloaded data contains action status (failed or successful) and links to the action runs. Then, we group actions by branch and workflow names, limiting them to up to three branches per repository and three workflows per branch to ensure data diversity. This way, we get the time-ordered list of actions for each branch-workflow combination. From it, we get a list of pairs of consecutive actions (workflow runs) where the first commit caused a failure of the GitHub workflow, and the next one was successful. Thus, we get a set of failed-success pairs of actions for each branch-workflow pair. We trim the set to three pairs per branch-workflow pair for data diversity.

For each extracted pair of actions, we download logs of the specific failed step of the failed workflow run, the diff between the failed and successful commits, and the meta-information of the failed commit. We filter out runs that take more than ten minutes, workflows that need tokens/secrets to run, and diffs lacking modifications of code files. Then, we assess the datapoints, verifying that logs contained all the necessary information to fix the issue, and grade the difficulty of solving datapoints on a 1–3 scale, with 1 corresponding to pure formatting problems, 2 — local (one-line) errors, 3 — requiring understanding of the complex file- or project-level dependencies to perform changes in multiple files.

To ensure that the benchmark works as intended, we re-run CI with and without the presumably correct fix that we got during the collection stage. We filter out the workflows that no longer constitute a failed-fixed pair. Finally, to isolate the problem to a single failure reason, we delete all .yaml files in the .github/workflows/ directory except for the failing workflow.

The total size of the final dataset is 77 items: 35 with difficulty 1, 14 — with difficulty 2, and 28 with difficulty 3. The median length of the logs is 6.5K symbols with an average of 145K symbols due to a few extremely long logs. The mean and median for the number of files in the repositories is 610 and 240, for the number of lines — 170K and 56K, number of symbols — 7.5M and 2.4M.

Evaluation. We provide the code for evaluation in our repository with baselines.[3](#page-3-0) After a model generates a patch for fixing the build, the benchmark uploads it to a separate branch in the forked GitHub repository and runs a CI workflow there. Then, it collects the results of the CI run, allowing us to compute the number of resolved runs and to check the arising mistakes. The target metric for the CI builds repair task is the percentage of successfully fixed builds.

Baselines. We run several LLMs on the CI builds repair benchmark. We use an *oracle* setup for the baselines, prompting the models to change the code blocks that were edited in the ground-truth fixing diff. To pass context from the build logs, we find the first occurrence of the case-insensitive substring "error" in the logs and take a seven-line context around this occurrence (three lines before and after). If the substring is not found, we pass seven last lines of the log. The instruction then reads as follows: "*Fix CI in order for tests to pass. Relevant logs: {relevant\_logs}*". We prompt the LLM to modify these code sections to align with the given instructions and pass all the sections in a single request. The LLM replies with the edited versions of the code sections that are converted into a diff and returned to the benchmark. The results for open-source models such as Mistral-7B [\[26\]](#page-9-10) and various versions of CodeLlama-Instruct [\[50\]](#page-11-4) range from 4% to 9% of successful fixes, while GPT-3.5 is able to resolve 17% of samples.

# 2.3 Project-Level Code Completion

Task description. The next task in the suite is project-level code completion, for now targeting the completion of single lines. We formulate the task as follows: given relevant information from the project, which we call *context*, and a prefix of the *completion file*, one needs to generate the next line in this file. While there exist other repository-level completion datasets [\[63,](#page-11-1) [39](#page-10-2)], we use project history from Git to mimic the real-world use case and avoid possible data leakages between files that arise when files in the context are written after the completed file and rely on the completed code. On top of that, we introduce a fine-grained classification of the completed lines by the used APIs.

Collection methodology. To create the dataset, we process the collected Python projects, traversing their Git histories to collect commits that were done after 01.01.2022. We extract newly added files from them, filtering out files with fewer than 200 lines or more than 2,000 lines. To collect the context for each file, we checkout the respective parent commit and save the contents of all the code and text files (*e.g.,* build files, documentation), constituting the repository as it was when the commit was made. Each datapoint contains the file for completion, a list of lines to complete with

<span id="page-3-0"></span><sup>3</sup>Code for running evaluation of CI builds repair: [https://github.com/JetBrains-Research/](https://github.com/JetBrains-Research/lca-baselines/tree/main/ci-builds-repair/ci-builds-repair-benchmark) [lca-baselines/tree/main/ci-builds-repair/ci-builds-repair-benchmark](https://github.com/JetBrains-Research/lca-baselines/tree/main/ci-builds-repair/ci-builds-repair-benchmark)

their categories (see the categorization below), and a repository snapshot that can be used to build the context.

We split our dataset into four parts based on the total size of .py files in the repository snapshot. As the reference for such a division, we chose the CodeLlama model [\[50\]](#page-11-4), which has a context window of size 16K and about three characters per token. Based on this, we have four sets of samples with the following limits on the total number of characters in the context .py files: *small-context set* from 0 to 16K × 3 = 48K characters; *medium-context set* from 48K to 192K characters; *large-context set* from 192K to 768K characters; *huge-context set* from 768K characters. We downsample datapoints to five datapoints per repository, and the repositories to 75 per set to ensure data diversity. The sizes of the four sets are 144, 224, 270, and 296 datapoints, respectively.

For each datapoint, we also provide a list of lines for completion—35 lines on average—since evaluating a code model on every line of a file is extremely resource-consuming. Moreover, not all lines are equally hard to complete; *e.g.,* function declaration lines can be challenging due to uncertainty, whereas loop definition can be straightforward. Taking that into account, we introduce a classification of the code lines into six categories depending on the used functions and classes. Categories *committed*, *inproject*, and *infile* refer to where the used functions/classes are defined: in the same commit as the completed file, in the project snapshot before the commit, or right in the completed file. *Common* category is assigned to the lines that contain common functions such as main or get. We classify lines as *non-informative* if they are too short, too long, contain prints, etc. (see Appendix [C](#page-25-0) for the full definition), and assign the *random* category to the rest of the lines.

While each line can fall into multiple categories based on the content, we only assign the "most difficult" category to each line in the following order (from difficult to easy): *committed*, *inproject*, *infile*, *common*. We then sample on average ten completion lines per datapoint for informative classes and five lines per datapoint for non-informative and random classes. Thus, for each file in the dataset, we have multiple lines that the model should complete. Total numbers of completion lines are 4,686, 8,676, 9,631, and 9,810 for each of four sets, respectively.

Metrics. The main metric for the project-level code completion task is the exact match of generated lines per category. This is a proportion of correct predictions calculated separately for each of the categories. The prediction is correct if it matches the ground truth after removing leading and trailing whitespaces from both.

Baselines. We evaluate CodeLlama-7B [\[50\]](#page-11-4) and DeepSeek Coder of sizes 1.3B and 6.7B [\[21](#page-9-13)]. For each model, we evaluate several strategies for composing the input context from the repository files (see Appendix [C](#page-25-0) for details). Among them, building the context from files closest in the file tree to the target file works best. The boosts for Exact Match for such a context composer for CodeLlama-7B on the medium context set are +16% for the *infile* lines and +53% for the *inproject* lines compared to using only the target file as context.

### 2.4 Commit Message Generation

Task description. The fourth benchmark that we present is commit message generation (CMG) for large commits. In CMG, a model should generate a natural language description of changes performed in a single commit. The changes can be represented in different ways — in various diff formats, as separate versions of each file before and after the changes took place, and others. Moreover, models can utilize information from unchanged project files to better understand how changes impacted the project. CMG is a well-established task in academic research [\[54](#page-11-5)] and a prominent feature in developer tools [\[9,](#page-8-7) [8\]](#page-8-8), however, researchers often limit the scope to short diffs [\[13\]](#page-9-7), leaving the performance on larger commits unexplored. Moreover, the quality of commit messages from open-source repositories—the most common data source—is notoriously mixed [\[57](#page-11-6)]. We bridge these two gaps with our novel CMG benchmark, manually curated and tailored for larger commits.

Collection methodology. We use the CommitChronicle [\[13\]](#page-9-7) dataset as the main data source. As the dataset aligns with our needs, we chose to use it rather than rebuild a dataset of commits from scratch from the repositories of Long Code Arena. CommitChronicle is a large-scale dataset with 10.7M commits from permissively licensed GitHub repositories in 20 programming languages. Notably, CommitChronicle omits restrictive data filtering steps, such as strict limits on the maximum length of code changes, thus fitting perfectly for our use case that targets larger diffs. As we are building a

benchmark, we use only the *test* subset of CommitChronicle. To make manual filtering possible, for now, we limit the work to the Python language and thus consider only the subset of the test set that includes changes to at least one .py file. This results in 172K commits from 455 repositories.

With CommitChronicle encompassing a wide array of commits, we follow the best practices from previous works [\[13,](#page-9-7) [44,](#page-10-6) [33\]](#page-10-7) to filter data and reduce the number of low-quality samples. Filtering criteria include minimum length in words and lines, message format, presence of hashes (for the exact criteria, see Appendix [D\)](#page-33-0). After the filtering, we retain 3,260 commits. Since we aim to target commits with larger changes, after the initial filtering, we only keep samples where the number of characters in diffs related to .py files is ≥ 3,000 characters. This leaves us with 858 commits that we further review manually to keep only those where the commit message provides a comprehensive description of all changes without introducing any external information and the changes are meaningful and non-trivial.

After manual filtering, our resulting dataset comprises 163 commits from 34 repositories. We follow the same format as the original CommitChronicle [\[13\]](#page-9-7) dataset and include commit diffs, commit messages, and relevant metadata that allows tracing each commit back to GitHub. To facilitate further experiments with constructing context for the CMG task, we provide the sources for all the repositories. Diffs in the dataset comprise from 67 to 800 lines, or 3.3K to 41K characters. When taking the full content of the changed files and other project files into account, the context spans from 4K to 5M lines, or 144K to 156M characters.

Metrics. We employ metrics used in previous works, including BLEU [\[45\]](#page-10-8), ROUGE [\[35\]](#page-10-9), ChrF [\[47](#page-10-4)], and BERTScore [\[64\]](#page-11-7). For BERTScore, we additionally include the normalized scores as proposed by the authors of the original metric [\[4](#page-8-9)] to allow for easier interpretation.

Baselines. We evaluate a range of proprietary and open-source models, including multiple OpenAI models, Mixtral-8x7B [\[27\]](#page-9-11), Mistral-7B [\[26](#page-9-10)], variations of DeepSeek Coder [\[21\]](#page-9-13), versions of CodeL-LaMA [\[50](#page-11-4)], and fine-tuned CodeT5 [\[60](#page-11-8)]. GPT-4 Turbo shows the best results with ChrF of 34.4. The best performing open-source model is Mixtral-8x7B with ChrF of 32, followed by Mistral-7B.

# 2.5 Bug Localization

Task description. The next problem addressed by the proposed benchmark is the bug localization task. This problem can be formulated as follows: given an issue with a bug description and a repository snapshot in a state where the bug is reproducible, identify the files within the repository that need to be modified to address the reported bug. Although this is a subset of the larger bug-fixing problem, partially covered by SWE-Bench [\[29\]](#page-9-14), bug localization requires its own separate evaluation. This independent assessment can provide a better understanding of the various approaches and their efficiency in identifying the precise location of bugs within the large code bases.

Collection methodology. To build the dataset for the bug localization task, we process the previously collected 8M issues and 7M PRs from GitHub with more than 34.4M comments. The provided issue data contains issue descriptions and labels (*e.g.*, "bug"), by which we can determine the reason behind creating the issue. For pull requests, we extract code diffs and link them to issues they resolve. We use regular expressions to parse links in PRs' titles, description comments, as well as issue comments (*e.g.*, "fixes #24" or "#25 resolved").

We filter the data to ensure data quality and limit the subset to programming languages familiar to the authors for manual labeling (see Appendix [E](#page-39-0) for the exact procedure). After this, we are left with 7,479 pairs of bug issues and pull requests linked to them. Out of them, 4,339 modify Python files, 2,522 — Java files, and 618 — Kotlin files. For each language, we manually examine a subset of datapoints to see that they meet the following criteria: the issue description is complete and fully describes the introduced changes, while the changes do indeed fix the issue and do not produce code irrelevant to it. Since manual labelling of the entire dataset of 7,479 samples is very time-consuming, we carry out the following procedure. For each language—Python, Java, and Kotlin—we manually examine samples iterating over the repositories from the most starred to the least starred, and stop after selecting 50 good datapoints per language. Importantly, for the initial set of 7,479 PRs, the median number of changed files is one. Given that, we select half the samples from fixes that only touch a single file, and half the samples from fixes that change from two to ten files. In terms of the context size, the median number of files in the repository is 331, with an average of 1K files. Each

file typically contains 1.5K tokens. Additionally, issues within the repository generally consist of approximately 150 words, equating to around 400 tokens.

Metrics. The task of bug localization is similar to information retrieval, so we use common metrics from this domain: recall at k (R@k), precision at k (P@k), F1 score (f1-score), and mean average precision (MAP). We select k to be equal to 1 for changes that require modification of a single file, and 2 for the rest of the changes. We compute metrics for these two cases separately and report both.

Baselines. First, we evaluate several retrieval-based approaches: TF-IDF, embeddings from CodeT5 [\[61\]](#page-11-9) and CodeBERT [\[15\]](#page-9-15), embedding models GTE [\[34\]](#page-10-10) and Mistral [\[43\]](#page-10-11). We use cosine distance between vectors for ranking. Furthermore, we evaluate BM25 [\[48\]](#page-10-5) retrieval provided by llama-index [\[37](#page-10-12)]. GTE model demonstrates the best result with 0.33 MAP, followed by Mistral with 0.3, and TF-IDF with the BPE tokenizer [\[52\]](#page-11-10) with 0.27. The results for the rest of the models are lower than 0.25 MAP.

We also evaluate two chat models — GPT-3.5 and GPT-4. We prompt them to indicate from one to five bugged files using the issue description and the full list of files from the repository. If the resulting prompt does not fit into the context size, we split the file list into several queries, followed by the final one that combines all outputs and asks to finalize the result. These approaches show better scores compared to the retrieval-based approaches, with GPT-4 achieving 0.39 MAP.

# 2.6 Module Summarization

Task description. The last benchmark in the suite is dedicated to the task of summarizing project modules into natural language. We formulate the module summarization task as follows: based on the module's or project's source code and intent (a one-sentence description of the expected documentation content), the model should write its textual documentation. This task greatly increases the context size available to the models compared to the existing benchmarks that cover method- or class-level summarization [\[25,](#page-9-16) [40](#page-10-13), [42](#page-10-14)]. The source of inspiration for the module summarization task is the fact that large projects often include high-level materials, such as quick start guides, tutorials, module documentation, and usage instructions. The task aims to alleviate the time-consuming and routine process of creating these materials.

Collection methodology. To collect the dataset, we gather documentation files—files with extensions .md, .txt, and .rst—that are located in the docs directory from the collected Python repositories. We then identify the associated code for each file by parsing the documentation and extracting links to files and directories with source code. Associated code files can encompass the entire project, particularly for quick-start documentation, or specific files for narrower cases. Searching for relevant code is essential to prevent the inclusion of text documents not related to specific parts of the source code, such as installation guides. If a file does not correspond to any module, we skip it. Subsequently, we remove documents that are fewer than ten lines of text without considering markup (*i.e.,* in plain text format). After the filtering steps, we are left with 461 files.

If a file passes all automatic filters, we review it manually before including into the dataset, ensuring that the text summarizes source code, and the other way around — information from source code is sufficient to write the documentation. This resulted in the final dataset of 216 files from 43 repositories, for each of which we manually specify an intent based on the documentation headers and contents.

For each datapoint, we attach the relevant context that was automatically extracted, as well as all the code from the repository with documentation files excluded. This enables researchers to experiment with different context collection techniques. The average length of the target documentation is 2,549 tokens (8,807 characters). The average length of the code context greatly depends on the sample and can be very large, as sometimes the context might include the code of the entire repository. Thus, the datapoint with minimum length of the relevant code context has 327 tokens, while the average and median length of code context are 18,572 and 21,286 tokens, respectively.

Metrics. Previous work [\[49\]](#page-11-11) shows that out of n-gram-based metrics, the ChrF metric [\[47\]](#page-10-4) works best for code summarization tasks. However, it was assessed for short texts, and our experience shows low sensitivity when discriminating long files. To overcome this limitation, we propose using LLMs as scalable proxies for human assessors, similar to the work of Chiang and Lee [\[7\]](#page-8-10).

Our proposed metric *CompScore* feeds an LLM the relevant code and two versions of documentation: the gold standard and the model-generated text. The LLM estimates the probability of one documentation better explaining and fitting the code than the other. To mitigate potential ordering effects in model responses, CompScore calculates the probability that the generated documentation is superior by averaging the results of two queries, swapping the order of the generated and reference documentation. The CompScore ranges from 0 to 100, with ground truth documentation receiving 50.

This scoring method not only provides a robust measure of documentation quality but also incorporates the flexibility and semantic evaluation capacity of human judgment. We use a local instance of Mistral-7B [\[26\]](#page-9-10) with a greedy generation algorithm to make the evaluation both cost-efficient and reproducible across various computational environments.

Baselines. We conduct all our experiments within a zero-shot setting. For every distinct sample, the model uses information about the target file name, intent, and the code we consider relevant (truncated to the supported length in tokens). We then compare the generated documentation with the ground truth provided in the dataset. We evaluate a range of proprietary and open-source models, including multiple OpenAI models, versions of Mixtral [\[27\]](#page-9-11), Mistral [\[26\]](#page-9-10), CodeLLaMA [\[50\]](#page-11-4), and LLaMA [\[58\]](#page-11-12). GPT-4 shows the best results with the CompScore of 57.3. The best performing open-source model is Llama2-70B with 48.2, followed by Llama2-13B and Mistral-7B-v0.3.

# 3 Related Work

While there exist plenty of ML4SE datasets and even benchmark collections [\[41](#page-10-15)], most of them require models to operate with rather short contexts, around the size of a single method, which hinders the evaluation of novel long context models. Code generation datasets [\[6,](#page-8-3) [2,](#page-8-4) [38,](#page-10-16) [23,](#page-9-8) [20,](#page-9-17) [62\]](#page-11-3) require models to process up to several paragraphs of the problem statement and then generate a short program (one line to one file). Existing datasets for code summarization [\[25,](#page-9-16) [41\]](#page-10-15) target documentation in a single method, meaning that both input and output size are below several hundred tokens. Previously developed commit message generation benchmarks [\[54](#page-11-5), [13,](#page-9-7) [51\]](#page-11-13) contain significantly shorter messages and diffs compared to Long Code Arena.

For code completion, recently, researchers introduced two benchmarks that operate at the repository scale: RepoEval [\[63\]](#page-11-1) and RepoBench [\[39\]](#page-10-2), also focusing on the completion of a single line. Compared to these benchmarks, we introduce a fine-grained classification of the completed lines and prevent possible data leakages by traversing Git history.

SWE-bench [\[29\]](#page-9-14) is a recent benchmark that requires models to fix issues in real-world programming projects. Long Code Arena covers a more diverse set of tasks, the most similar being CI builds repair, which focuses on builds in general rather than tests, and bug localization, which is a sub-task of the SWE-bench objective that we evaluate on a broader set of languages: Python, Java, and Kotlin.

The most notable benchmarks for long context models include Long Range Arena [\[55](#page-11-14)] and Scrolls [\[53\]](#page-11-15). Our work builds the first such benchmark focusing on ML4SE tasks, while Long Range Arena includes synthetic problems and Scrolls focuses on natural language processing.

# 4 Limitations and Future Work

In order to gather benchmarks for Long Code Arena, we had to make several design decisions that can impact the generalizability. First, we base the benchmarks on open-source data. This allows researchers to experiment with various context-collection techniques because they have access to source code data. On the other hand, modern LLMs use most available open-source data for training, and such reliance can lead to data contamination, which in turn can skew the evaluation results.

We argue that the tasks that we choose are less prone to models memorizing training data: there is no direct link between answers to benchmark tasks and raw repository data that modern models use for training. For example, while models could have seen documentation of specific libraries during training, currently it is unlikely that it was present side by side with the source code of the respective modules. The most memorization-prone task in our suite is code completion, but for it, we use historic data from Git repositories, which may become changed or overridden by the moment LLMs' training data is scraped.

In order to allow for manual examination of the collected data and to keep the benchmarks consistent, for most tasks we focus on datasets of Python code. Fortunately, the data preparation pipeline for all the tasks can be reused to produce datasets for other languages. The most complex step in this case will be manual verification and filtering of the data to ensure quality and correctness. In order to meet the quality requirement, we leave extension of datasets to other languages for future work.

In addition to extending datasets to other programming languages, future work includes collecting data for fine-tuning models for particular tasks and evaluating more models on the benchmarks. In order to assist other researchers with the latter, we open-source the code for the baseline solutions.

# 5 Conclusion

In this paper, we present the *Long Code Arena*. The goal of this work is to stimulate research in MLbased solutions for realistic software engineering tasks. In particular, we design a series of tasks that require taking a complex context into account, such as full projects, libraries and their usage, and coarse-grained components. Our work presents six benchmarks related to code generation, repair, completion, and summarization. For each task, we carefully design and manually curate evaluation data, metrics for assessing the results, and baseline solutions based on the pre-trained models. Our experiments show that the tasks are within reach, but far from solved. We hope and expect that our Long Code Arena will encourage researchers in ML4SE and NLP communities to advance the field of ML-enabled software engineering.

# References

- <span id="page-8-6"></span>[1] Josh Achiam, Steven Adler, Sandhini Agarwal, Lama Ahmad, Ilge Akkaya, Florencia Leoni Aleman, Diogo Almeida, Janko Altenschmidt, Sam Altman, Shyamal Anadkat, et al. GPT-4 technical report. *arXiv preprint arXiv:2303.08774*, 2023.
- <span id="page-8-4"></span>[2] Jacob Austin, Augustus Odena, Maxwell Nye, Maarten Bosma, Henryk Michalewski, David Dohan, Ellen Jiang, Carrie Cai, Michael Terry, Quoc Le, et al. Program synthesis with large language models. *arXiv preprint arXiv:2108.07732*, 2021.
- <span id="page-8-2"></span>[3] Amanda Bertsch, Uri Alon, Graham Neubig, and Matthew Gormley. Unlimiformer: Longrange transformers with unlimited length input. *Advances in Neural Information Processing Systems*, 36, 2024.
- <span id="page-8-9"></span>[4] BERTScore Normalization, 2024. [https://github.com/Tiiiger/bert\\_score/blob/](https://github.com/Tiiiger/bert_score/blob/master/journal/rescale_baseline.md) [master/journal/rescale\\_baseline.md](https://github.com/Tiiiger/bert_score/blob/master/journal/rescale_baseline.md).
- <span id="page-8-0"></span>[5] Sebastian Borgeaud, Arthur Mensch, Jordan Hoffmann, Trevor Cai, Eliza Rutherford, Katie Millican, George Bm Van Den Driessche, Jean-Baptiste Lespiau, Bogdan Damoc, Aidan Clark, et al. Improving language models by retrieving from trillions of tokens. In *International conference on machine learning*, pages 2206–2240. PMLR, 2022.
- <span id="page-8-3"></span>[6] Mark Chen, Jerry Tworek, Heewoo Jun, Qiming Yuan, Henrique Ponde de Oliveira Pinto, Jared Kaplan, Harri Edwards, Yuri Burda, Nicholas Joseph, Greg Brockman, et al. Evaluating large language models trained on code. *arXiv preprint arXiv:2107.03374*, 2021.
- <span id="page-8-10"></span>[7] Cheng-Han Chiang and Hung-yi Lee. Can large language models be an alternative to human evaluations? *arXiv preprint arXiv:2305.01937*, 2023.
- <span id="page-8-8"></span>[8] Commit message generation feature in GitHub Copilot, 2024. [https://devblogs.]( https://devblogs.microsoft.com/visualstudio/write-your-git-commits-with-github-copilot/) [microsoft.com/visualstudio/write-your-git-commits-with-github-copilot/]( https://devblogs.microsoft.com/visualstudio/write-your-git-commits-with-github-copilot/).
- <span id="page-8-7"></span>[9] Commit message generation feature in JetBrains IDEs, 2024. [https://blog.jetbrains.]( https://blog.jetbrains.com/idea/2023/06/ai-assistant-in-jetbrains-ides/) [com/idea/2023/06/ai-assistant-in-jetbrains-ides/]( https://blog.jetbrains.com/idea/2023/06/ai-assistant-in-jetbrains-ides/).
- <span id="page-8-5"></span>[10] Ozren Dabic, Emad Aghajani, and Gabriele Bavota. Sampling projects in GitHub for MSR studies. In *18th IEEE/ACM International Conference on Mining Software Repositories, MSR 2021*, pages 560–564. IEEE, 2021.
- <span id="page-8-1"></span>[11] Tri Dao. FlashAttention-2: Faster attention with better parallelism and work partitioning. *arXiv preprint arXiv:2307.08691*, 2023.
- <span id="page-8-11"></span>[12] Tim Dettmers, Mike Lewis, Younes Belkada, and Luke Zettlemoyer. GPT3.int8(): 8-bit matrix multiplication for transformers at scale. *Advances in Neural Information Processing Systems*, 35:30318–30332, 2022.
- <span id="page-9-7"></span>[13] Aleksandra Eliseeva, Yaroslav Sokolov, Egor Bogomolov, Yaroslav Golubev, Danny Dig, and Timofey Bryksin. From commit message generation to history-aware commit message completion. In *2023 38th IEEE/ACM International Conference on Automated Software Engineering (ASE)*, pages 723–735. IEEE, 2023.
- <span id="page-9-9"></span>[14] Mikhail Evtikhiev, Egor Bogomolov, Yaroslav Sokolov, and Timofey Bryksin. Out of the BLEU: how should we assess quality of the code generation models? *Journal of Systems and Software*, 203:111741, 2023.
- <span id="page-9-15"></span>[15] Zhangyin Feng, Daya Guo, Duyu Tang, Nan Duan, Xiaocheng Feng, Ming Gong, Linjun Shou, Bing Qin, Ting Liu, Daxin Jiang, et al. CodeBERT: A pre-trained model for programming and natural languages. *arXiv preprint arXiv:2002.08155*, 2020.
- <span id="page-9-4"></span>[16] Dan Fu, Simran Arora, Jessica Grogan, Isys Johnson, Evan Sabri Eyuboglu, Armin Thomas, Benjamin Spector, Michael Poli, Atri Rudra, and Christopher Ré. Monarch Mixer: A simple sub-quadratic GEMM-based architecture. *Advances in Neural Information Processing Systems*, 36, 2024.
- <span id="page-9-2"></span>[17] Yunfan Gao, Yun Xiong, Xinyu Gao, Kangxiang Jia, Jinliu Pan, Yuxi Bi, Yi Dai, Jiawei Sun, and Haofen Wang. Retrieval-augmented generation for large language models: A survey. *arXiv preprint arXiv:2312.10997*, 2023.
- <span id="page-9-12"></span>[18] GitHub Actions, 2024. [https://github.com/features/actions]( https://github.com/features/actions).
- <span id="page-9-5"></span>[19] Albert Gu and Tri Dao. Mamba: Linear-time sequence modeling with selective state spaces. *arXiv preprint arXiv:2312.00752*, 2023.
- <span id="page-9-17"></span>[20] Alex Gu, Baptiste Rozière, Hugh Leather, Armando Solar-Lezama, Gabriel Synnaeve, and Sida I. Wang. CRUXEval: A benchmark for code reasoning, understanding and execution. *arXiv preprint arXiv:2401.03065*, 2024.
- <span id="page-9-13"></span>[21] Daya Guo, Qihao Zhu, Dejian Yang, Zhenda Xie, Kai Dong, Wentao Zhang, Guanting Chen, Xiao Bi, Y Wu, YK Li, et al. DeepSeek-Coder: When the large language model meets programming–the rise of code intelligence. *arXiv preprint arXiv:2401.14196*, 2024.
- <span id="page-9-1"></span>[22] Vincent J Hellendoorn, Sebastian Proksch, Harald C Gall, and Alberto Bacchelli. When code completion fails: A case study on real-world completions. In *2019 IEEE/ACM 41st International Conference on Software Engineering (ICSE)*, pages 960–970. IEEE, 2019.
- <span id="page-9-8"></span>[23] Dan Hendrycks, Steven Basart, Saurav Kadavath, Mantas Mazeika, Akul Arora, Ethan Guo, Collin Burns, Samir Puranik, Horace He, Dawn Song, et al. Measuring coding challenge competence with APPS. In *Thirty-fifth Conference on Neural Information Processing Systems Datasets and Benchmarks Track (Round 2)*, 2021.
- <span id="page-9-0"></span>[24] Xinyi Hou, Yanjie Zhao, Yue Liu, Zhou Yang, Kailong Wang, Li Li, Xiapu Luo, David Lo, John Grundy, and Haoyu Wang. Large language models for software engineering: A systematic literature review. *arXiv preprint arXiv:2308.10620*, 2023.
- <span id="page-9-16"></span>[25] Hamel Husain, Ho-Hsiang Wu, Tiferet Gazit, Miltiadis Allamanis, and Marc Brockschmidt. CodeSearchNet challenge: Evaluating the state of semantic code search. *arXiv preprint arXiv:1909.09436*, 2019.
- <span id="page-9-10"></span>[26] Albert Q Jiang, Alexandre Sablayrolles, Arthur Mensch, Chris Bamford, Devendra Singh Chaplot, Diego de las Casas, Florian Bressand, Gianna Lengyel, Guillaume Lample, Lucile Saulnier, et al. Mistral 7b. *arXiv preprint arXiv:2310.06825*, 2023.
- <span id="page-9-11"></span>[27] Albert Q Jiang, Alexandre Sablayrolles, Antoine Roux, Arthur Mensch, Blanche Savary, Chris Bamford, Devendra Singh Chaplot, Diego de las Casas, Emma Bou Hanna, Florian Bressand, et al. Mixtral of experts. *arXiv preprint arXiv:2401.04088*, 2024.
- <span id="page-9-3"></span>[28] Zhengbao Jiang, Frank F Xu, Luyu Gao, Zhiqing Sun, Qian Liu, Jane Dwivedi-Yu, Yiming Yang, Jamie Callan, and Graham Neubig. Active retrieval augmented generation. *arXiv preprint arXiv:2305.06983*, 2023.
- <span id="page-9-14"></span>[29] Carlos E Jimenez, John Yang, Alexander Wettig, Shunyu Yao, Kexin Pei, Ofir Press, and Karthik Narasimhan. SWE-bench: Can language models resolve real-world GitHub issues? *arXiv preprint arXiv:2310.06770*, 2023.
- <span id="page-9-6"></span>[30] Eirini Kalliamvakou, Georgios Gousios, Kelly Blincoe, Leif Singer, Daniel M German, and Daniela Damian. The promises and perils of mining GitHub. In *Proceedings of the 11th working conference on mining software repositories*, pages 92–101, 2014.
- <span id="page-10-0"></span>[31] Vladimir Kovalenko, Nava Tintarev, Evgeny Pasynkov, Christian Bird, and Alberto Bacchelli. Does reviewer recommendation help developers? *IEEE Transactions on Software Engineering*, 46(7):710–731, 2018.
- <span id="page-10-17"></span>[32] Jiawei Li and Iftekhar Ahmed. Commit message matters: Investigating impact and evolution of commit message quality. In *2023 IEEE/ACM 45th International Conference on Software Engineering (ICSE)*, pages 806–817. IEEE, 2023.
- <span id="page-10-7"></span>[33] Raymond Li, Loubna Ben Allal, Yangtian Zi, Niklas Muennighoff, Denis Kocetkov, Chenghao Mou, Marc Marone, Christopher Akiki, Jia Li, Jenny Chim, et al. StarCoder: may the source be with you! *arXiv preprint arXiv:2305.06161*, 2023.
- <span id="page-10-10"></span>[34] Zehan Li, Xin Zhang, Yanzhao Zhang, Dingkun Long, Pengjun Xie, and Meishan Zhang. Towards general text embeddings with multi-stage contrastive learning. *arXiv preprint arXiv:2308.03281*, 2023.
- <span id="page-10-9"></span>[35] Chin-Yew Lin. Rouge: A package for automatic evaluation of summaries. In *Text summarization branches out*, pages 74–81, 2004.
- <span id="page-10-3"></span>[36] Wang Ling, Phil Blunsom, Edward Grefenstette, Karl Moritz Hermann, Tomáš Kocisk ˇ y, Fumin ` Wang, and Andrew Senior. Latent predictor networks for code generation. In *Proceedings of the 54th Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers)*, pages 599–609, 2016.
- <span id="page-10-12"></span>[37] Jerry Liu. LlamaIndex, 2022. URL [https://github.com/jerryjliu/llama\\_index](https://github.com/jerryjliu/llama_index).
- <span id="page-10-16"></span>[38] Jiawei Liu, Chunqiu Steven Xia, Yuyao Wang, and Lingming Zhang. Is your code generated by ChatPGT really correct? Rigorous evaluation of large language models for code generation. *Advances in Neural Information Processing Systems*, 36, 2024.
- <span id="page-10-2"></span>[39] Tianyang Liu, Canwen Xu, and Julian McAuley. RepoBench: Benchmarking repository-level code auto-completion systems. *arXiv preprint arXiv:2306.03091*, 2023.
- <span id="page-10-13"></span>[40] Anton Lozhkov, Raymond Li, Loubna Ben Allal, Federico Cassano, Joel Lamy-Poirier, Nouamane Tazi, Ao Tang, Dmytro Pykhtar, Jiawei Liu, Yuxiang Wei, et al. StarCoder 2 and The Stack v2: The Next Generation. *arXiv preprint arXiv:2402.19173*, 2024.
- <span id="page-10-15"></span>[41] Shuai Lu, Daya Guo, Shuo Ren, Junjie Huang, Alexey Svyatkovskiy, Ambrosio Blanco, Colin Clement, Dawn Drain, Daxin Jiang, Duyu Tang, et al. CodeXGLUE: A machine learning benchmark dataset for code understanding and generation. *arXiv preprint arXiv:2102.04664*, 2021.
- <span id="page-10-14"></span>[42] Qinyu Luo, Yining Ye, Shihao Liang, Zhong Zhang, Yujia Qin, Yaxi Lu, Yesai Wu, Xin Cong, Yankai Lin, Yingli Zhang, et al. RepoAgent: An LLM-powered open-source framework for repository-level code documentation generation. *arXiv preprint arXiv:2402.16667*, 2024.
- <span id="page-10-11"></span>[43] Rui Meng, Ye Liu, Shafiq Rayhan Joty, Caiming Xiong, Yingbo Zhou, and Semih Yavuz. SFR-Embedding-Mistral: Enhance text retrieval with transfer learning. Salesforce AI Research Blog, 2024. URL [https://blog.salesforceairesearch.com/](https://blog.salesforceairesearch.com/sfr-embedded-mistral/) [sfr-embedded-mistral/](https://blog.salesforceairesearch.com/sfr-embedded-mistral/).
- <span id="page-10-6"></span>[44] Niklas Muennighoff, Qian Liu, Armel Randy Zebaze, Qinkai Zheng, Binyuan Hui, Terry Yue Zhuo, Swayam Singh, Xiangru Tang, Leandro Von Werra, and Shayne Longpre. OctoPack: instruction tuning code large language models. In *The Twelfth International Conference on Learning Representations*, 2023.
- <span id="page-10-8"></span>[45] Kishore Papineni, Salim Roukos, Todd Ward, and Wei-Jing Zhu. Bleu: A method for automatic evaluation of machine translation. In *Proceedings of the 40th annual meeting of the Association for Computational Linguistics*, pages 311–318, 2002.
- <span id="page-10-1"></span>[46] Michael Poli, Stefano Massaroli, Eric Nguyen, Daniel Y Fu, Tri Dao, Stephen Baccus, Yoshua Bengio, Stefano Ermon, and Christopher Ré. Hyena hierarchy: Towards larger convolutional language models. In *International Conference on Machine Learning*, pages 28043–28078. PMLR, 2023.
- <span id="page-10-4"></span>[47] Maja Popovic. chrF: character n-gram F-score for automatic MT evaluati ´ on. In *Proceedings of the Tenth Workshop on Statistical Machine Translation*, pages 392–395, 2015.
- <span id="page-10-5"></span>[48] Stephen Robertson, Hugo Zaragoza, et al. The probabilistic relevance framework: BM25 and beyond. *Foundations and Trends® in Information Retrieval*, 3(4):333–389, 2009.
- <span id="page-11-11"></span>[49] Devjeet Roy, Sarah Fakhoury, and Venera Arnaoudova. Reassessing automatic evaluation metrics for code summarization tasks. In *Proceedings of the 29th ACM Joint Meeting on European Software Engineering Conference and Symposium on the Foundations of Software Engineering*, pages 1105–1116, 2021.
- <span id="page-11-4"></span>[50] Baptiste Roziere, Jonas Gehring, Fabian Gloeckle, Sten Sootla, Itai Gat, Xiaoqing Ellen Tan, Yossi Adi, Jingyu Liu, Tal Remez, Jérémy Rapin, et al. Code Llama: Open foundation models for code. *arXiv preprint arXiv:2308.12950*, 2023.
- <span id="page-11-13"></span>[51] Maximilian Schall, Tamara Czinczoll, and Gerard de Melo. CommitBench: A benchmark for commit message generation. *arXiv preprint arXiv:2403.05188*, 2024.
- <span id="page-11-10"></span>[52] Rico Sennrich, Barry Haddow, and Alexandra Birch. Neural machine translation of rare words with subword units. In *Proceedings of the 54th Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers)*, pages 1715–1725, 2016.
- <span id="page-11-15"></span>[53] Uri Shaham, Elad Segal, Maor Ivgi, Avia Efrat, Ori Yoran, Adi Haviv, Ankit Gupta, Wenhan Xiong, Mor Geva, Jonathan Berant, et al. SCROLLS: standardized comparison over long language sequences. In *Proceedings of the 2022 Conference on Empirical Methods in Natural Language Processing*, pages 12007–12021, 2022.
- <span id="page-11-5"></span>[54] Wei Tao, Yanlin Wang, Ensheng Shi, Lun Du, Shi Han, Hongyu Zhang, Dongmei Zhang, and Wenqiang Zhang. A large-scale empirical study of commit message generation: models, datasets and evaluation. *Empirical Software Engineering*, 27(7):198, 2022.
- <span id="page-11-14"></span>[55] Yi Tay, Mostafa Dehghani, Samira Abnar, Yikang Shen, Dara Bahri, Philip Pham, Jinfeng Rao, Liu Yang, Sebastian Ruder, and Donald Metzler. Long range arena: A benchmark for efficient transformers. *arXiv preprint arXiv:2011.04006*, 2020.
- <span id="page-11-0"></span>[56] Yi Tay, Mostafa Dehghani, Dara Bahri, and Donald Metzler. Efficient transformers: A survey. *ACM Computing Surveys*, 55(6):1–28, 2022.
- <span id="page-11-6"></span>[57] Yingchen Tian, Yuxia Zhang, Klaas-Jan Stol, Lin Jiang, and Hui Liu. What makes a good commit message? In *Proceedings of the 44th International Conference on Software Engineering*, pages 2389–2401, 2022.
- <span id="page-11-12"></span>[58] Hugo Touvron, Louis Martin, Kevin Stone, Peter Albert, Amjad Almahairi, Yasmine Babaei, Nikolay Bashlykov, Soumya Batra, Prajjwal Bhargava, Shruti Bhosale, et al. Llama 2: Open foundation and fine-tuned chat models. *arXiv preprint arXiv:2307.09288*, 2023.
- <span id="page-11-2"></span>[59] Christopher Vendome, Gabriele Bavota, Massimiliano Di Penta, Mario Linares-Vásquez, Daniel German, and Denys Poshyvanyk. License usage and changes: A large-scale study on GitHub. *Empirical Software Engineering*, 22:1537–1577, 2017.
- <span id="page-11-8"></span>[60] Yue Wang, Weishi Wang, Shafiq Joty, and Steven CH Hoi. CodeT5: Identifier-aware unified pre-trained encoder-decoder models for code understanding and generation. In *Proceedings of the 2021 Conference on Empirical Methods in Natural Language Processing*, pages 8696– 8708, 2021.
- <span id="page-11-9"></span>[61] Yue Wang, Hung Le, Akhilesh Gotmare, Nghi Bui, Junnan Li, and Steven Hoi. CodeT5+: Open code large language models for code understanding and generation. In *Proceedings of the 2023 Conference on Empirical Methods in Natural Language Processing*, pages 1069– 1088, 2023.
- <span id="page-11-3"></span>[62] Pengcheng Yin, Bowen Deng, Edgar Chen, Bogdan Vasilescu, and Graham Neubig. Learning to mine aligned code and natural language pairs from Stack Overflow. In *Proceedings of the 15th international conference on mining software repositories*, pages 476–486, 2018.
- <span id="page-11-1"></span>[63] Fengji Zhang, Bei Chen, Yue Zhang, Jacky Keung, Jin Liu, Daoguang Zan, Yi Mao, Jian-Guang Lou, and Weizhu Chen. RepoCoder: repository-level code completion through iterative retrieval and generation. In *Proceedings of the 2023 Conference on Empirical Methods in Natural Language Processing*, pages 2471–2484, 2023.
- <span id="page-11-7"></span>[64] Tianyi Zhang, Varsha Kishore, Felix Wu, Kilian Q Weinberger, and Yoav Artzi. BERTScore: evaluating text generation with BERT. In *International Conference on Learning Representations*, 2019.

# Supplementary Materials (Long Code Arena)

These supplementary materials include the following:

- 1. Appendix [A](#page-12-0) datasheet for the Library-based code generation dataset.
- 2. Appendix [B](#page-18-0) datasheet for the CI builds repair dataset.
- 3. Appendix [C](#page-25-0) datasheet for the Project-level code completion dataset.
- 4. Appendix [D](#page-33-0) datasheet for the Commit message generation dataset.
- 5. Appendix [E](#page-39-0) datasheet for the Bug localization dataset.
- 6. Appendix [F](#page-47-0) datasheet for the Module summarization dataset.

# <span id="page-12-0"></span>A Datasheet for the Library-Based Code Generation Dataset

# A.1 Motivation

# Q1 For what purpose was the dataset created?

• The dataset for the library-based code generation task is a part of Long Code Arena, a set of six benchmarks that cover different aspects of code processing. The most important feature of Long Code Arena is utilization of module- or project-level contexts for all the tasks, code generation included. Thus, the purpose of this dataset is to evaluate how good machine learning models can utilize data from an entire software project when solving the code generation task.

# Q2 Who created this dataset (*e.g.*, which team, research group) and on behalf of which entity (*e.g.,* company, institution, organization)?

• This dataset is created by the JetBrains Research team, in particular, by the authors of this paper.

# Q3 Who funded the creation of the dataset?

• This work was conducted at JetBrains Research and therefore was funded by JetBrains, a vendor of specialized development tools.

### Q4 Any other comments?

• No.

# A.2 Composition

### Q5 What do the instances that comprise the dataset represent?

• Each of the 150 samples in the dataset represents an instruction that a machine learning model should follow when generating a Python program, reference data for evaluation of the generation quality, and relevant data that can be used to improve generation. This relevant data is the source code of an entire Python library, based on a usage example from which we created the instruction for generation.

### Q6 How many instances are there in total (of each type, if appropriate)?

- There are 150 datapoints in total.
- Q7 Does the dataset contain all possible instances or is it a sample (not necessarily random) of instances from a larger set?
	- The dataset is a sample. It comes from a larger set of Python repositories.

### Q8 What data does each instance consist of?

• The structure of the datapoints is presented in Table [1.](#page-13-0)

### Q9 Is there a label or target associated with each instance?

• The labels are available in two forms: the reference program that was written by library authors as an example of library usage, and the list of library-specific API calls that the reference program makes. Both the program itself and the list of API calls can be used to assess the quality of a program generated by a machine learning model under evaluation.

| Field                    | Description                                                                                                             |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------|
| repo_full_name           | Concatenated repository name and owner                                                                                  |
| repo_name                | Library repository name                                                                                                 |
| repo_owner               | Library repository owner                                                                                                |
| instruction              | Task for code generation                                                                                                |
| reference                | Reference program written by the library authors                                                                        |
| clean_reference          | Reference program with comments removed                                                                                 |
| path_to_reference_file   | Path to the reference in the repository (removed in<br>repository snapshots to prevent data leakages)                   |
| path_to_examples_folder  | Path to the directory with examples in the repos<br>itory (removed in repository snapshots to prevent<br>data leakages) |
| n_unique_apis            | Number of calls to library-specific APIs in the ref<br>erence program                                                   |
| unique_apis              | List of calls to library-specific APIs in the refer<br>ence program                                                     |
| project_defined_elements | All class and method names in the repository                                                                            |
| api_calls                | All API calls in the reference program                                                                                  |
| internal_apis            | All API calls to the respective library in the refer                                                                    |
|                          | ence program                                                                                                            |

<span id="page-13-0"></span>Table 1: The structure of datapoints in the library-based code generation dataset.

### Q10 Is any information missing from individual instances?

• No.

### Q11 Are relationships between individual instances made explicit?

- All instances are independent, yet may share properties such as the same contributor or repository, which are represented as fields in the dataset.
- Q12 Are there recommended data splits (*e.g.*, training, development/validation, testing)?
	- The dataset only contains data for evaluation (*i.e.*, testing split).
- Q13 Are there any errors, sources of noise, or redundancies in the dataset?
	- See the description of preprocessing in [Q22.](#page-14-0)
- Q14 Is the dataset self-contained, or does it link to or otherwise rely on external resources?
	- The dataset is self-contained, as it provides the snapshots of all associated repositories.
- Q15 Does the dataset contain data that might be considered confidential?
	- This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained confidential materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered confidential.

### Q16 Does the dataset contain data that, if viewed directly, might be offensive, insulting, threatening, or might otherwise cause anxiety?

• The data comes from GitHub, and hence must comply with GitHub's acceptable use policy, in particular concerning user safety. We also manually verified our data and did not find any violation.

### Q17 Does the dataset relate to people?

- The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.
- Q18 Does the dataset identify any subpopulations (*e.g.*, by age, gender)?
- We do not provide any markers of subpopulations, since people are not the focus of the dataset. However, some indicators might be possible to deduce by following individual datapoints to their source.
- Q19 Is it possible to identify individuals (*i.e.*, one or more natural persons), either directly or indirectly (*i.e.*, in combination with other data) from the dataset?
	- The data was collected from GitHub and thus might be traced back to GitHub users.
- Q20 Does the dataset contain data that might be considered sensitive in any way?
	- This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained sensitive materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered sensitive.

### Q21 Any other comments?

• No.

### <span id="page-14-0"></span>A.3 Collection

### Q22 How was the data associated with each instance acquired?

- To collect the data, we use the following protocol:
	- (a) We collect repositories from GitHub with at least 1,000 commits, at least ten contributors, issues, and stars, at least 10,000 lines of code, not a fork, last commit after 01.06.2023, and a permissive license (we use the most popular permissive licenses — MIT, Apache-2.0, BSD-3-Clause, and BSD-2-Clause). For the libraryspecific code generation task, we leave only repositories having Python as the main language.
	- (b) For each repository, we detect the folder with usage examples: a folder with ".py" files that contains "examples" in its name. If a repository does not have such a folder, we filter it out. After this step, we are left with 883 repositories that have usage examples.
	- (c) We then identify library-specific APIs for each of the 883 repositories. We extract all names of all methods, classes, and constants defined in these repositories, and treat as "library-specific" the ones that appear only in a single repository.
	- (d) We then collect all Python files from the folders with examples and filter them: (i) remove examples shorter than 100 or longer than 40,000 characters (excluding comments), (ii) remove examples that have fewer than 400 characters of comments in order to then write high-quality instruction for generation, (iii) remove examples that use fewer than ten API calls specific to the given library. These filters result in 150 files (usage examples) from 62 libraries, with each file heavily relying on the APIs of the respective project.
	- (e) After we have the usage examples for libraries, we create instructions for generating them. We first run the selected 150 files through GPT-4 [\[1\]](#page-8-6), prompting it to generate an instruction for generating the respective file. You can see the prompt for generation in Figure [1.](#page-15-0) This leaves us with step-by-step instructions that the LLM should then follow to generate a script that utilizes the library at hand. Then, we manually fix each instruction in order to reduce hinting to specific library methods and ensure their correctness.
- Q23 What mechanisms or procedures were used to collect the data (*e.g.*, hardware apparatus or sensor, manual human curation, software program, software API)?
	- We use GitHub Search [\[10\]](#page-8-5) to collect the initial list of repositories. We use GitHub API for data collection. We use OpenAI's GPT-4 [\[1\]](#page-8-6) to generate instructions for code generation and then conduct manual curation of the instructions by the paper authors having more than six years of experience of software development in Python.
- Q24 If the dataset is a sample from a larger set, what was the sampling strategy?
	- The dataset is sampled from a larger set of repositories by selecting only repositories with Python as the main language and further filtering as described in [Q22.](#page-14-0)

SYSTEM: We are developing a benchmark to assess quality of code generation models. As a part of the benchmark, we include the task of generating code based that uses the particular library from a description in natural language. As a source of data for this task we will use coding examples in Python provided by library developers. Your task will be to generate a text description of the provided Python code that will then be used as an input for the generation task.

USER: Here is the code. You should write an instruction that summarizes its contents and would allow another model to generate this snippet of code, excluding the comments. Make the instruction abstract, do not mention specific code constructions that the generator should use. Be concise. Generator will be able to access the contents of the following library: [LIBRARY\_NAME]. Use wording such as "Generate code that ..." in your instruction.

[CODE]

<span id="page-15-0"></span>Figure 1: Prompt for generating instructions from library usage examples.

- Q25 Who was involved in the data collection process (*e.g.*, students, crowdworkers, contractors) and how were they compensated?
	- The data collection process was conducted by the authors of this paper.
- Q26 Over what timeframe was the data collected?
- The construction of this dataset took place between October 2023 and January 2024.
- Q27 Were any ethical review processes conducted?
	- No.
- Q28 Does the dataset relate to people?
	- The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.
- Q29 Did you collect the data from the individuals in question directly, or obtain it via third parties or other sources (*e.g.*, websites)?
	- We collected the data from GitHub, a website hosting code and artifacts written by humans.
- Q30 Were the individuals in question notified about the data collection?
	- Individuals were not notified about the data collection, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused.
- Q31 Did the individuals in question consent to the collection and use of their data?
	- We did not ask for consent directly, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused. We made sure our data collection procedure is in line with GitHub's acceptable use policies.
- Q32 If consent was obtained, were the consenting individuals provided with a mechanism to revoke their consent in the future or for certain uses?
	- On our HuggingFace Space, we provide information on how individuals can request removals.
- Q33 Has an analysis of the potential impact of the dataset and its use on data subjects been conducted?
	- Since individuals are not the focus of our dataset, we foresee at most limited impact. Users of the dataset might attempt to trace back artifacts to individuals (via GitHub)

and try to reach out to them (via contact information on GitHub) with questions about their artifacts.

### Q34 Any other comments?

• No.

### A.4 Preprocessing / Cleaning / Labeling

### Q35 Was any preprocessing/cleaning/labeling of the data done?

• We describe the steps for creating the dataset for library-specific code generation in [Q22.](#page-14-0)

### Q36 Was the "raw" data saved in addition to the preprocessed/cleaned/labeled data?

• We include into the dataset both repository snapshots and human-written programs that served as a basis for the tasks. The larger set of repositories before filtering steps is not provided in the dataset.

### Q37 Is the software used to preprocess/clean/label the instances available?

- The code for preprocessing is available on demand by contacting the authors.
- Q38 Any other comments?

• No.

### <span id="page-16-0"></span>A.5 Uses

### Q39 Has the dataset been used for any tasks already?

- We use the dataset to assess the quality of models in the library-based code generation task. To do so, we develop and evaluate multiple baselines solutions, and propose two metrics for assessing quality:
	- (a) We measure ChrF [\[47\]](#page-10-4) between the generated code and the reference program written by developers of the respective library as a usage example. ChrF estimates similarity between two texts, or code snippets as in our case, using character ngrams. Previous study [\[14\]](#page-9-9) has shown that it is more robust compared to other metrics when assessing code generation quality.
	- (b) We also propose to use *API Recall*, the ratio of library-specific methods and classes used in the reference solution that also appear in the generated code. The metric assumes that a model that solves the generation task well should be able to identify useful APIs in the library, the same as library developers utilized in the provided usage example.
- We develop and evaluate baselines based on six popular LLMs in two setups. For models, we use proprietary GPT-3.5-turbo and GPT-4 [\[1\]](#page-8-6), and instruction-tuned versions of open-source CodeLlama-7B, CodeLlama-70B [\[50\]](#page-11-4), Mistral-7B [\[26\]](#page-9-10), and Mixtral-8x7B [\[27](#page-9-11)]. In the first setup, we run the models without any information from the library aside from the instruction for generation that recommends using it. In the second setup, we treat instruction as a query and use BM-25 to find top-20 most relevant class and method names in the library. To do so, we also split the names by snake\_case and camelCase, remove punctuation from them, and turn them into lower case. Then, we add the retrieved method names to the instruction and propose the model under evaluation to use them.
- Table [2](#page-17-0) shows the results of evaluation for the baselines. GPT-4 shows the best quality according to both metrics, with GPT-3.5 following it. Notably, CodeLlama-70B shows the worst quality by far. This happens because the model refused to answer the code generation request for most of the queries, answering with a stub message. Models aside from GPT-4 get very low API Recall, showing that they are not well familiar with the libraries that we want them to use. We treat this as a success for the benchmark, as it suggests that using open-source libraries (that models may have seen during training) does not make the task easy. Using a simplistic retrieval approach to enhance context allows to add a few points to API Recall for most models, however, the task remains far from being solved.

<span id="page-17-0"></span>

|               |      | No context | With retrieved APIs |            |  |
|---------------|------|------------|---------------------|------------|--|
|               | ChrF | API Recall | ChrF                | API Recall |  |
| GPT-4         | 0.41 | 0.37       | 0.39                | 0.36       |  |
| GPT-3.5       | 0.26 | 0.17       | 0.26                | 0.19       |  |
| CodeLlama-7B  | 0.28 | 0.09       | 0.29                | 0.15       |  |
| Mistral-7B    | 0.30 | 0.07       | 0.31                | 0.13       |  |
| Mixtral-8x7B  | 0.29 | 0.11       | 0.29                | 0.13       |  |
| CodeLlama-70B | 0.06 | 0.02       | 0.11                | 0.04       |  |

Table 2: Results of baselines for the library-based code generation task.

### Q40 Is there a repository that links to any or all papers or systems that use the dataset?

• The dataset is currently used in our repository with baselines available on GitHub.

### Q41 What tasks could the dataset be used for?

- The dataset can be used for assessing models solving the library-based code generation task, as explained in [Q39.](#page-16-0)
- Q42 Is there anything about the composition of the dataset or the way it was collected and preprocessed/cleaned/labeled that might impact future uses?
	- Not in the data itself. As per the GitHub acceptable usage requirements, researchers using this dataset must make any papers resulting from it available as open access.
- Q43 Are there tasks for which the dataset should not be used?
	- To the best of our knowledge, no.
- Q44 Any other comments?
	- No.

### A.6 Distribution

- Q45 Will the dataset be distributed to third parties outside of the entity?
	- Yes, the dataset is publicly available on the internet.
- Q46 How will the dataset be distributed? Does the dataset have a digital object identifier (DOI)?
	- The dataset is available through DOI at the HuggingFace Hub: [https://doi.org/](https://doi.org/10.57967/hf/2510) [10.57967/hf/2510](https://doi.org/10.57967/hf/2510).
- Q47 When will the dataset be distributed?
	- The dataset is already publicly available.
- Q48 Will the dataset be distributed under a copyright or other intellectual property (IP) license, and/or under applicable terms of use (ToU)?
	- Data coming from GitHub will be re-distributed under the license it was distributed with originally on GitHub (for which we only used permissive licenses). The terms of use require that research conducted with this dataset makes any resulting paper available as open access, in line with GitHub's requirements.
- Q49 Have any third parties imposed IP-based or other restrictions on the data associated with the instances?
	- No.
- Q50 Do any export controls or other regulatory restrictions apply to the dataset or to individual instances?
	- To the best of our knowledge, no.
- Q51 Any other comments?
	- No.

### A.7 Maintenance

- Q52 Who is supporting/hosting/maintaining the dataset?
	- The dataset will be maintained by the JetBrains Research team.
- Q53 How can the owner/curator/manager of the dataset be contacted (*e.g.*, email address)?
	- The dataset curators can be contacted via email at lca@jetbrains.com.
- Q54 Is there an erratum?
	- There is no erratum as of June 2024.
- Q55 Will the dataset be updated? (*e.g.*, to correct labeling errors, add new instances, delete instances)?
	- The dataset will be extended to more languages and samples over the course of time.
- Q56 If the dataset relates to people, are there applicable limits on the retention of the data associated with the instances?
	- On the HuggingFace Space, we provide information on how individuals can request removals.
- Q57 Will older versions of the dataset continue to be supported/hosted/maintained?
	- The older versions will be kept around for consistency.
- Q58 If others want to extend/augment/build on/contribute to the dataset, is there a mechanism for them to do so?
	- We welcome all contributions and encourage others to contact the dataset curators via the provided email.
- Q59 Any other comments?
	- No.

# <span id="page-18-0"></span>B Datasheet for the CI Builds Repair dataset

### B.1 Motivation

- Q1 For what purpose was the dataset created?
	- CI builds repair dataset is a part of the Long Code Arena aimed at evaluating models on repository-level long-context real-life tasks. CI builds repair benchmark is aimed at testing models in fixing real-life issues in continuous integration. We use the functionality and data of GitHub Actions [\[18](#page-9-12)], a popular continuous integration and continuous deployment (CI/CD) service. The minimal set of data for the task consists of a repository snapshot at the commit that caused the failure of the CI workflow and the logs of the failed step. Based on the provided data, the model under evaluation has to generate a patch for the project that will make the build pass. The testing then happens by running CI workflows for the repository with the generated patch.
- Q2 Who created this dataset (*e.g.*, which team, research group) and on behalf of which entity (*e.g.,* company, institution, organization)?
	- This dataset is created by the JetBrains Research team, in particular, by the authors of this paper.

### Q3 Who funded the creation of the dataset?

• This work was conducted at JetBrains Research and therefore was funded by JetBrains, a vendor of specialized development tools.

### Q4 Any other comments?

• No.

| Field             | Description                                                                                 |  |  |
|-------------------|---------------------------------------------------------------------------------------------|--|--|
| contributor       | The username of the contributor that committed changes                                      |  |  |
| difficulty        | The difficulty of the problem according to an assessor on<br>a 1–3 scale                    |  |  |
| diff              | Contents of the diff between the failed and the successful<br>commits                       |  |  |
| head_branch       | Name of the original branch that the commit was pushed<br>to                                |  |  |
| id                | Unique ID of the datapoint                                                                  |  |  |
| language          | The main language of the repository                                                         |  |  |
| logs              | List of dictionaries with logs of the failed job and name<br>of the failed step in this job |  |  |
| repo_name         | Name of the original repository                                                             |  |  |
| repo_owner        | Owner of the original repository                                                            |  |  |
| sha_fail          | SHA of the failed commit                                                                    |  |  |
| sha_success       | SHA of the successful commit                                                                |  |  |
| workflow          | Contents of the workflow file                                                               |  |  |
| workflow_filename | The name of the workflow file (without full path)                                           |  |  |
|                   | workflow_name<br>The name of the workflow                                                   |  |  |
| workflow_path     | The full path to the workflow file                                                          |  |  |
| changed_files     | List of files changed in the diff                                                           |  |  |
| commit_link       | URL to a commit corresponding to the failed job                                             |  |  |

<span id="page-19-0"></span>Table 3: The structure of datapoints in the CI builds repair dataset.

### B.2 Composition

### Q5 What do the instances that comprise the dataset represent?

- The dataset instances for the CI builds repair task consist of a repository snapshot at the commit with failing CI, the logs of the failed CI step, a diff that fixes the CI, and various metadata. We include diffs to help dataset users to compare the answers of their models with a ground truth solution. We do not store repository snapshots and fetch them from GitHub during benchmarking to reduce the dataset's memory requirements. To ensure the repositories are available, we forked them to a separate organization.
- Q6 How many instances are there in total (of each type, if appropriate)?
	- There are 77 datapoints in total.
- Q7 Does the dataset contain all possible instances or is it a sample (not necessarily random) of instances from a larger set?
	- The dataset is a sample. It comes from a larger set of GitHub Actions builds in Python repositories.
- Q8 What data does each instance consist of?
	- The structure of the datapoints is presented in Table [3.](#page-19-0)
- Q9 Is there a label or target associated with each instance?
	- There is no label or target in the dataset. The goal of the benchmark is to submit a fix to a GitHub repository that will make the CI build pass. We provide code for evaluation in our GitHub repository.

### Q10 Is any information missing from individual instances?

• No.

- Q11 Are relationships between individual instances made explicit?
	- All instances are independent, yet may share properties such as the same contributor or repository, which are represented as fields in the dataset.
- Q12 Are there recommended data splits (*e.g.*, training, development/validation, testing)?

• The dataset only contains data for evaluation (*i.e.*, testing split).

### Q13 Are there any errors, sources of noise, or redundancies in the dataset?

• We describe the preprocessing strategy in [Q22](#page-20-0) and discuss the possible obsoletion of the datapoints in [Q55.](#page-25-1)

### Q14 Is the dataset self-contained, or does it link to or otherwise rely on external resources?

• The dataset does not store the repository snapshots but rather fetches them from GitHub during benchmarking to reduce the dataset's memory requirements. Otherwise, the dataset is self-contained.

### Q15 Does the dataset contain data that might be considered confidential?

• This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained confidential materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered confidential.

### Q16 Does the dataset contain data that, if viewed directly, might be offensive, insulting, threatening, or might otherwise cause anxiety?

• The data comes from GitHub, and hence must comply with GitHub's acceptable use policy, in particular concerning user safety. We also manually verified our data and did not find any violation.

### Q17 Does the dataset relate to people?

• The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.

### Q18 Does the dataset identify any subpopulations (*e.g.*, by age, gender)?

- We do not provide any markers of subpopulations, since people are not the focus of the dataset. However, some indicators might be possible to deduce by following individual datapoints to their source.
- Q19 Is it possible to identify individuals (*i.e.*, one or more natural persons), either directly or indirectly (*i.e.*, in combination with other data) from the dataset?
	- The data was collected from GitHub and thus might be traced back to GitHub users.

### Q20 Does the dataset contain data that might be considered sensitive in any way?

- This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained sensitive materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered sensitive.
- Q21 Any other comments?
	- No.

### <span id="page-20-0"></span>B.3 Collection

### Q22 How was the data associated with each instance acquired?

- To collect the data, we used the following protocol:
	- (a) For all the collected Python repositories, we get the full list of the actions run in the repository, limited to last 90 days. Downloaded data contains action status (failed or successful) and links to the action runs.
- (b) We gather a list of pairs of consecutive commits in which the first commit causes a failure of a workflow but the next one makes it build successfully.
- (c) For each pair of commits, we download:
	- logs of the failed step of the failed commit;
	- diff between the failed and successful commit (*correction diff*);

– metadata of the failed commit.

During the download, we clean the data according to the following filters (on the fly, to avoid excessive requests to GitHub API):

- To reduce the benchmarking time, we eliminate runs that take more than 10 minutes (measured on successful action run).
- To minimize the number of actions that contain pure formatting issues, we filter out datapoints, in which the names of the workflow, target, or failed step contain any of the following substrings: {*mypy*, *lint*, *flake8*, *black*}. We allow these substrings in the target name if there is more than one target in the action run.
- We remove runs for which the workflow file contains substrings {*token*, *secret*} to ensure that we can run them without any prerequisites.
- We keep only datapoints for which the correction diff (i) contains at least one .py file, and (ii) only contains files that match either of the following items: {code file, *\*.md*, *\*.rst*, *LICENSE\**, *readme\**, *doc/\**}. We do so to ensure that there are no changes in artifacts such as resources or data files, which the model cannot fix given the present context.
- (d) To isolate the problem to a single issue per datapoint, when running the benchmark, we delete all .yaml files in the .github/workflows/ directory, ensuring that only this workflow would be run. We also remove workflows that contain links to other workflow files to make sure that the target workflow is independent.
- Q23 What mechanisms or procedures were used to collect the data (*e.g.*, hardware apparatus or sensor, manual human curation, software program, software API)?
	- We use GitHub API to collect the data and further manual verification and assessment to filter it.
- Q24 If the dataset is a sample from a larger set, what was the sampling strategy?
	- The dataset is sampled from a larger set of repositories by selecting only repositories with Python as the main language. Also, we only collect CI builds over the period of 90 days and then filter them as described in [Q22.](#page-20-0)
- Q25 Who was involved in the data collection process (*e.g.*, students, crowdworkers, contractors) and how were they compensated?
	- The data collection process was conducted by the authors of this paper.
- Q26 Over what timeframe was the data collected?
	- The dataset has been collected in December of 2023. Only datapoints spanning three months before collection have been gathered, since logs of the GitHub Actions are stored only for 90 days. Thus, the dataset collection timeframe is October–December of 2023.

### Q27 Were any ethical review processes conducted?

• No.

### Q28 Does the dataset relate to people?

• The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.

### Q29 Did you collect the data from the individuals in question directly, or obtain it via third parties or other sources (*e.g.*, websites)?

• We collected the data from GitHub, a website hosting code and artifacts written by humans.

### Q30 Were the individuals in question notified about the data collection?

- Individuals were not notified about the data collection, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused.
- Q31 Did the individuals in question consent to the collection and use of their data?

<span id="page-22-0"></span>

| Table 4: Number of datapoints on each mining step. |  |  |  |  |
|----------------------------------------------------|--|--|--|--|
|                                                    |  |  |  |  |

| Data mining step                                     | # of datapoints |
|------------------------------------------------------|-----------------|
| Initial set of sampled workflows                     | 336             |
| Datapoints that passed assessor verification         | 210             |
| Datapoints that passed GitHub Actions                | 144             |
| Datapoints that passed GitHub Actions after 6 months | 77              |

• We did not ask for consent directly, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused. We made sure our data collection procedure is in line with GitHub's acceptable use policies.

### Q32 If consent was obtained, were the consenting individuals provided with a mechanism to revoke their consent in the future or for certain uses?

- On our HuggingFace Space, we provide information on how individuals can request removals.
- Q33 Has an analysis of the potential impact of the dataset and its use on data subjects been conducted?
	- Since individuals are not the focus of our dataset, we foresee at most limited impact. Users of the dataset might attempt to trace back artifacts to individuals (via GitHub) and try to reach out to them (via contact information on GitHub) with questions about their artifacts.

### Q34 Any other comments?

• No.

### B.4 Preprocessing / Cleaning / Labeling

### Q35 Was any preprocessing/cleaning/labeling of the data done?

- The basic data filters are described in the data collection procedure in [Q22.](#page-20-0) Here, we provide further filtering steps.
	- (a) We limited ourselves to the 100 largest Python repositories (main language: Python, the ratio of the main language > 0.95) with permissive licences. From each repository, we take no more than three branches, for each branch — no more than three different workflows, and for each workflow — no more than three datapoints. Thus, each repository could contribute up to 27 datapoints. The automated data collection process resulted in 336 datapoints (see Table [4\)](#page-22-0).
	- (b) The human assessor assessed the datapoints to verify that logs contain all the necessary information to fix the issue and graded the datapoints on a 1–3 scale according to their difficulty. Table [5](#page-23-0) describes the difficulty levels and the sizes of the available buckets.
	- (c) In the last step, we run all datapoints through our benchmark at both the failed and the successful commit. We then keep only the datapoints that remained failing / passing at the respective commits. Moreover, we repeat the procedure after 6 months from the initial procedure to ensure the durability of the dataset. This last step is crucial as it filtered out 50% of the datapoints: quite many passing workflows started failing due to changes in library versions that were not specified by repository owners, connection issues, missing remote files or certificates. Table [4](#page-22-0) reports the number of filtered datapoints at each step.

### Q36 Was the "raw" data saved in addition to the preprocessed/cleaned/labeled data?

• No.

# Q37 Is the software used to preprocess/clean/label the instances available?

- The code for preprocessing is available on demand by contacting the authors.
- Q38 Any other comments?
	- Context-related statistics are presented in Table [6.](#page-23-1)

| Difficulty | # of datapoints | Description                                                            |
|------------|-----------------|------------------------------------------------------------------------|
| 1          | 35              | Issues with formatting                                                 |
| 2          | 14              | Local issues or issues with typing                                     |
| 3          | 28              | Issues that require information about<br>other files in the repository |
| Total      | 77              |                                                                        |

<span id="page-23-0"></span>Table 5: Data split by the difficulty.

<span id="page-23-1"></span>

| Table 6: Context-related statistics. |  |  |  |
|--------------------------------------|--|--|--|
|--------------------------------------|--|--|--|

| Context metric        | Mean | Median |
|-----------------------|------|--------|
| Symbols in logs       | 145K | 6.5K   |
| Files in repository   | 610  | 240    |
| Lines in repository   | 170K | 56K    |
| Symbols in repository | 7.5M | 2.4M   |

### B.5 Uses

### Q39 Has the dataset been used for any tasks already?

- We use the collected dataset to assess multiple LLMs in the CI builds repair task. To make the task easier to tackle, we provide models with an oracle — when asking to fix the build, we also provide the list of files and specific code blocks in them that should be fixed. The information on which files need fixing comes from the ground truth commit that fixed the build. In the future, if the task becomes too easy for the models, oracle can be simply removed to make the task even more realistic and challenging.
- To prompt the models to solve the task, we use the following strategy. To prepare an instruction, we locate the first occurrence of the case-insensitive substring "error" in the logs and take a 7-line context around this occurrence (3 lines before and after). If the substring is not found, we use 7 last log lines. The instruction then reads as follows: "*Fix CI in order for tests to pass. Relevant logs: {relevant\_logs}*". We then prompt the LLM to modify the code blocks provided by an oracle to align with the given instructions, and pass all the code blocks in a single request in the following way:

```
[start of file.py#L12]
...code line 12...
...code line 13...
...
[end of file.py#L12]
```
• After an LLM replies with the edited versions of the code sections, we convert them into a diff and apply the resulting patch to the repository. Then, the developed benchmark sends the updated version of the repository to GitHub Actions and collects the results. Table [7](#page-24-0) shows the evaluation results for several models: proprietary GPT-3.5 and GPT-4 [\[1\]](#page-8-6), open-source versions of Llama-2 [\[58](#page-11-12)], Mistral-7B [\[26](#page-9-10)], and Mixtral-8x7B [\[27](#page-9-11)].

### Q40 Is there a repository that links to any or all papers or systems that use the dataset?

• The dataset is currently used in our repository with baselines available on GitHub.

### Q41 What tasks could the dataset be used for?

- We implement the benchmark for using the CI builds repair dataset in our repository. The benchmark requires a user-implemented function (*fix\_repo\_function*) that repairs locally stored repository, given the logs of a failing build. The procedure is the following:
	- (a) The benchmark clones each repository snapshot with depth equal to 1 to a local machine.

<span id="page-24-0"></span>Table 7: Pass@1 scores of the CI builds repair benchmark for various LLMs

| Model        | Pass@1 |
|--------------|--------|
| Mistral-7B   | 0.065  |
| Mixtral-8x7B | 0.039  |
| Llama-2-7B   | 0.065  |
| Llama-2-13B  | 0.065  |
| Llama-2-34B  | 0.091  |
| GPT-3.5      | 0.169  |
| GPT-4        | 0.156  |

- (b) Then, the benchmark runs the model under evaluation, which takes a datapoint as input (mainly — log and workflow files) and needs to repair the repository on the local machine by editing or replacing files.
- (c) The benchmark edits the workflow files to run only one workflow.
- (d) Then, it pushes the current state of the repository to a new branch in the separate GitHub organization.
- (e) When results of builds in GitHub Actions become available, the benchmark collects, analyzes, and returns them.
- To use the benchmark, one needs to send a request to join the GitHub organization[4](#page-24-1) since the procedure requires pushing changes to repositories in that organization. Moreover, keeping repositories as forks in a separate organization ensures that they will remain available. The function *fix\_repo\_function* takes the following (all optional) arguments:
	- (a) datapoint: datapoint from the dataset
	- (b) repo\_path: path to the repository on the user's machine
	- (c) repo: git.Repo object from the GitPython library
	- (d) out\_folder: directory for outputting the benchmark results
- Intermediate results contain datapoint ID and meta information, as well as the SHA of the commit pushed to the target repository. After collecting the results, the benchmark adds the status of the GitHub Actions build to this information.

### Q42 Is there anything about the composition of the dataset or the way it was collected and preprocessed/cleaned/labeled that might impact future uses?

• Not in the data itself. As per the GitHub acceptable usage requirements, researchers using this dataset must make any papers resulting from it available as open access.

### Q43 Are there tasks for which the dataset should not be used?

- To the best of our knowledge, no.
- Q44 Any other comments?

• No.

### B.6 Distribution

- Q45 Will the dataset be distributed to third parties outside of the entity?
	- Yes, the dataset is publicly available on the internet.
- Q46 How will the dataset be distributed? Does the dataset have a digital object identifier (DOI)?
	- The dataset is available through DOI at the HuggingFace Hub: [https://doi.org/](https://doi.org/10.57967/hf/2511) [10.57967/hf/2511](https://doi.org/10.57967/hf/2511).
- Q47 When will the dataset be distributed?
	- The dataset is already publicly available..

<span id="page-24-1"></span><sup>4</sup>GitHub Organization for the benchmark: <https://github.com/LCA-CI-builds-repair>

- Q48 Will the dataset be distributed under a copyright or other intellectual property (IP) license, and/or under applicable terms of use (ToU)?
	- Data coming from GitHub will be re-distributed under the license it was distributed with originally on GitHub (for which we only used permissive licenses). The terms of use require that research conducted with this dataset makes any resulting paper available as open access, in line with GitHub's requirements.
- Q49 Have any third parties imposed IP-based or other restrictions on the data associated with the instances?

• No.

- Q50 Do any export controls or other regulatory restrictions apply to the dataset or to individual instances?
	- To the best of our knowledge, no.
- Q51 Any other comments?
	- No.

### B.7 Maintenance

### Q52 Who is supporting/hosting/maintaining the dataset?

- The dataset will be maintained by the JetBrains Research team.
- Q53 How can the owner/curator/manager of the dataset be contacted (*e.g.*, email address)?
	- The dataset curators can be contacted via email at lca@jetbrains.com.
- Q54 Is there an erratum?
	- There is no erratum as of June 2024.
- <span id="page-25-1"></span>Q55 Will the dataset be updated? (*e.g.*, to correct labeling errors, add new instances, delete instances)?
	- The dataset will be extended to more languages and samples in the future work. Also, since the task assessment relies on a loosely controlled GitHub Actions framework, there is a risk that some datapoints may become invalid over the course of time, as has already happened over the 6 months after the data gathering. We will continue updating the dataset with new datapoints and removing the ones that become obsolete with time.

### Q56 If the dataset relates to people, are there applicable limits on the retention of the data associated with the instances?

- On the HuggingFace Space, we provide information on how individuals can request removals.
- Q57 Will older versions of the dataset continue to be supported/hosted/maintained?
	- The older versions will be kept around for consistency.
- Q58 If others want to extend/augment/build on/contribute to the dataset, is there a mechanism for them to do so?
	- We welcome all contributions and encourage others to contact the dataset curators via the provided email.
- Q59 Any other comments?
	- No.

# <span id="page-25-0"></span>C Datasheet for the Project-Level Code Completion Dataset

### C.1 Motivation

Q1 For what purpose was the dataset created?

- Project-level code completion dataset is a part of Long Code Arena suite of benchmarks. The dataset can be used to evaluate approaches in utilizing long context in the code completion task. In this dataset, we avoid possible data leakages by analyzing Git history, introduce a classification of completion lines, and provide entire repositories as a context. The benchmark is composed of four self-sufficient sets with various context sizes.
- Q2 Who created this dataset (*e.g.*, which team, research group) and on behalf of which entity (*e.g.,* company, institution, organization)?
	- This dataset is created by the JetBrains Research team, in particular, by the authors of this paper.

### Q3 Who funded the creation of the dataset?

• This work was conducted at JetBrains Research and therefore was funded by JetBrains, a vendor of specialized development tools.

### Q4 Any other comments?

• No.

# C.2 Composition

# Q5 What do the instances that comprise the dataset represent?

• Each instance that comprises the dataset consists of three key elements: a repository snapshot, a completion file, and target lines for the completion task. A repository snapshot is a list of all the filenames and contents of all text files from the repository (code, documentation, etc.). The state of the repository is before the commit where the completion file was added. A completion file is a Python file added in a particular commit. Target lines are a list of lines from the completion file that the model under evaluation should generate. Each line is also assigned one of classes that we describe in [Q35.](#page-29-0)

# Q6 How many instances are there in total (of each type, if appropriate)?

- There are 934 datapoints in total, divided between four sets. Note that while each datapoint contains a single completion file, it requires the model to generate multiple lines in it.
	- (a) *small-context* set contains 144 datapoints.
	- (b) *medium-context* set contains 224 datapoints.
	- (c) *large-context* set contains 270 datapoints.
	- (d) *huge-context* set contains 296 datapoints.
- Q7 Does the dataset contain all possible instances or is it a sample (not necessarily random) of instances from a larger set?

• The dataset is a sample. It comes from a larger set of Python repositories and commits.

# Q8 What data does each instance consist of?

- The structure of datapoints:
	- repo repository name in the format {GitHub\_user\_name}\_\_{repository\_name}
	- commit\_hash hash of the commit where the completion file was added
	- completion\_file dictionary with the completion file content in the following format:
		- \* filename path to the completion file
		- \* content content of the completion file
	- completion\_lines dictionary where keys are categories of lines and values are a list of integers (numbers of lines to complete). The categories are described in [Q35.](#page-29-0)
	- repo\_snapshot dictionary with a snapshot of the repository before the commit. Has the same structure as completion\_file, but filenames and contents are organized as lists.
	- completion\_lines\_raw the same as completion\_lines, but before sampling.

### Q9 Is there a label or target associated with each instance?

• Targets for the completion task are provided in the completion\_lines field. To get a target line for completion, split the completion file by newline characters and select lines using the provided indices. Line categories are also provided.

### Q10 Is any information missing from individual instances?

• No. However, during the collection process we focused only on the text-based files. While filenames for all files are included in the repository snapshot, the content of non-text files (*e.g.,* images) is recorded as None.

### Q11 Are relationships between individual instances made explicit?

• All instances are independent, yet may share properties such as the same contributor or repository, which are represented as fields in the dataset.

### Q12 Are there recommended data splits (*e.g.*, training, development/validation, testing)?

• The dataset only contains data for evaluation (*i.e.*, testing split).

### Q13 Are there any errors, sources of noise, or redundancies in the dataset?

• The repository snapshots are intentionally not filtered to ensure that all possible information could be utilized. As a result, the dataset includes sources of noise, such as auto-generated files, CSV data, etc.

### Q14 Is the dataset self-contained, or does it link to or otherwise rely on external resources?

• The dataset is self-contained.

### Q15 Does the dataset contain data that might be considered confidential?

• This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained confidential materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered confidential.

### Q16 Does the dataset contain data that, if viewed directly, might be offensive, insulting, threatening, or might otherwise cause anxiety?

• The data comes from GitHub, and hence must comply with GitHub's acceptable use policy, in particular concerning user safety. We also manually verified our data and did not find any violation.

### Q17 Does the dataset relate to people?

• The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.

### Q18 Does the dataset identify any subpopulations (*e.g.*, by age, gender)?

• We do not provide any markers of subpopulations, since people are not the focus of the dataset. However, some indicators might be possible to deduce by following individual datapoints to their source.

### Q19 Is it possible to identify individuals (*i.e.*, one or more natural persons), either directly or indirectly (*i.e.*, in combination with other data) from the dataset?

• The data was collected from GitHub and thus might be traced back to GitHub users.

### Q20 Does the dataset contain data that might be considered sensitive in any way?

• This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained sensitive materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered sensitive.

### Q21 Any other comments?

• No.

### C.3 Collection

- Q22 How was the data associated with each instance acquired?
	- Starting with the common corpus of repositories, we then follow the following process to acquire the data:
		- (a) Traverse Git history: We collect commits that add at least one new .py file. These files are candidates for the completion files.
		- (b) Filtering collected commits: We filter the commits to retain only those with the potential completion files containing between 200 and 2,000 lines, and with creation dates after January 1st, 2022.
		- (c) Extract repository snapshots: We create snapshots of the repositories based on the filtered commits, ensuring that we capture the state of the repository before the collected commit.
		- (d) Split by the size of relevant context: We split all the data into four groups based on the number of characters in .py files from the repository snapshots. The groups are: (i) *small-context*: less than 48K characters; (ii) *medium-context*: from 48K to 192K characters; (iii) *large-context*: from 192K to 768K characters; (iv) *hugecontext*: more than 768K characters;
		- (e) Sample datapoints: we randomly sample 5 datapoints for each repository, and we randomly sample 75 repositories for each group. If fewer than 5 datapoints or 75 repositories are available, we use all available datapoints or repositories. We keep all 80 repositories for the *medium-context* dataset.
		- (f) Classify lines: We perform line classification that is introduced in the paper and assign a main category to each line of the completion file.
		- (g) Sample completion lines: We sample lines from each category such that the average number of lines is no more than 5 for *non-informative* and *random* categories, and no more than 10 for other categories.
- Q23 What mechanisms or procedures were used to collect the data (*e.g.*, hardware apparatus or sensor, manual human curation, software program, software API)?
	- Data collection utilized GitHub API. Further, we used manual verification and assessment for data filtering.
- Q24 If the dataset is a sample from a larger set, what was the sampling strategy?
	- We use the following sampling strategy for the datapoints when creating a dataset from a larger set of GitHub repositories:
		- (a) If there are more than 5 datapoints from the same repository in a dataset, randomly sample 5.
		- (b) If there are more than 75 different repositories in a dataset, randomly sample 75. We keep all 80 repositories for the *medium-context* set.
	- We also filter the completion files:
		- (a) The file contains from 200 to 2,000 lines.
		- (b) The file was added to the repository after January 1st, 2022.
	- Finally, we sample the completion lines:
		- (a) Sample 5 lines for *non-informative* and *random* categories.
		- (b) Remove exact duplicates by sampling 1 line from a set of exact duplicates.
		- (c) For each class except *non-informative* and *random*, remove 1 randomly chosen line from a datapoint with a maximum number of lines until we have an average not greater than 10.
- Q25 Who was involved in the data collection process (*e.g.*, students, crowdworkers, contractors) and how were they compensated?
	- The data collection process was conducted by the authors of this paper.
- Q26 Over what timeframe was the data collected?
	- The dataset has been collected in December of 2023. Considering the filtering process, the data within the dataset spans from January 2022 to December 2023.
- Q27 Were any ethical review processes conducted?

• No.

### Q28 Does the dataset relate to people?

- The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.
- Q29 Did you collect the data from the individuals in question directly, or obtain it via third parties or other sources (*e.g.*, websites)?
	- We collected the data from GitHub, a website hosting code and artifacts written by humans.

### Q30 Were the individuals in question notified about the data collection?

• Individuals were not notified about the data collection, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused.

### Q31 Did the individuals in question consent to the collection and use of their data?

• We did not ask for consent directly, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused. We made sure our data collection procedure is in line with GitHub's acceptable use policies.

### Q32 If consent was obtained, were the consenting individuals provided with a mechanism to revoke their consent in the future or for certain uses?

• On our HuggingFace Space, we provide information on how individuals can request removals.

### Q33 Has an analysis of the potential impact of the dataset and its use on data subjects been conducted?

• Since individuals are not the focus of our dataset, we foresee at most limited impact. Users of the dataset might attempt to trace back artifacts to individuals (via GitHub) and try to reach out to them (via contact information on GitHub) with questions about their artifacts.

### Q34 Any other comments?

• No.

### <span id="page-29-0"></span>C.4 Preprocessing / Cleaning / Labeling

### Q35 Was any preprocessing/cleaning/labeling of the data done?

- Classification of the lines is done for each of the completion files. There are six categories of completion lines according to various completion scenarios.
	- (a) *infile* a line contains at least one function or class that was declared in the completion file.
	- (b) *inproject* a line contains at least one function or class that was declared in the repository snapshot files.
	- (c) *common* a line contains at least one function or class that was classified to be common, *e.g.*, main, get, etc.
	- (d) *committed* a line contains at least one function or class that was declared in the files that were created in the same commit as the completion file (excluding the completion file).
	- (e) *non-informative* a line that satisfies at least on of the following criteria: (i) shorter than 5 characters or longer than 150 characters, (ii) a line with print, (iii) a line with import, (iv) a declaration of a function or a class, (v) a comment or contains an inline comment.
	- (f) *random* all the lines that do not have any category.
- Some lines may have more than one category after the classification. We additionally identify the main category for each line based on the following approach.
	- If a line has a *committed* category, then the main category is *committed*.

| Set    | infile | inproject | common | committed | non-informative | random | all   | Avg. for one file |
|--------|--------|-----------|--------|-----------|-----------------|--------|-------|-------------------|
| Small  | 1,430  | 95        | 500    | 1,426     | 532             | 703    | 4,686 | 32.5              |
| Medium | 2,224  | 2,236     | 779    | 1,495     | 858             | 1,084  | 8,676 | 38.7              |
| Large  | 2,691  | 2,595     | 693    | 1,322     | 1,019           | 1,311  | 9,631 | 35.7              |
| Huge   | 2,608  | 2,901     | 692    | 1,019     | 1,164           | 1,426  | 9,810 | 33.1              |

<span id="page-30-0"></span>Table 8: Line counts for different sets in the project-level code completion dataset.

- If a line does not satisfy the previous condition, but has an *inproject* category, then the main category is *inproject*.
- If a line does not satisfy previous conditions, but has an *infile* category, then the main category is *infile*.
- If a line does not satisfy previous conditions, but has a *common* category, then the main category is *common*.
- If a line has a *non-informative* category, then the main category is *non-informative*.
- If a line has a *random* category, then this is the only category for the line, and the main category is *random*.

### Q36 Was the "raw" data saved in addition to the preprocessed/cleaned/labeled data?

• No.

# Q37 Is the software used to preprocess/clean/label the instances available?

• The code for preprocessing is available on demand by contacting the authors.

# Q38 Any other comments?

• We provide a distribution of lines for each set and each category in Table [8.](#page-30-0)

# C.5 Uses

# Q39 Has the dataset been used for any tasks already?

- We use the dataset to evaluate how well pre-trained code LLMs can utilize context from the given repository. We provide the evaluation results for CodeLlama 7B in Table [9](#page-31-0) (see the [online leaderboard](https://huggingface.co/spaces/JetBrains-Research/long-code-arena) for other models).
- We evaluate publicly available models as baselines without any modifications or finetuning. We implement several approaches to compose the context that fits into the model's context window (see [Q44\)](#page-31-1). One of the best performing composers is the Path distance composer, for which the results are present in Table [9.](#page-31-0) This composer chooses .py files from the repository snapshot that are in the same directory as the completion file or in the nearby directories, first picking files closer in the file tree to the completion file. As the context window sizes for all models are limited, we truncate the input sequence to the respective context size.
- We also report the results for the file-level context, which feeds the models only the prefix of the completion file for each completion line.

# Q40 Is there a repository that links to any or all papers or systems that use the dataset?

- The dataset is currently used in our repository with baselines available on GitHub.
- Q41 What tasks could the dataset be used for?
	- The provided dataset can be used in different tasks:
		- to evaluate various approaches to utilize long context for code models, *e.g.,* retrieval-augmented generation, support of long context windows, etc.;
		- to explore how code files in other languages or non-code files affect code completion;
		- to compare benefits from long contexts with the associated increase in costs.
- Q42 Is there anything about the composition of the dataset or the way it was collected and preprocessed/cleaned/labeled that might impact future uses?
	- Not in the data itself. As per the GitHub acceptable usage requirements, researchers using this dataset must make any papers resulting from it available as open access.

| Set    | Context           | infile | inproject | committed | common | non-informative | random | all  |
|--------|-------------------|--------|-----------|-----------|--------|-----------------|--------|------|
|        | File-level        | 0.35   | 0.16      | 0.33      | 0.32   | 0.28            | 0.42   | 0.35 |
| Small  | Path Distance 16K | 0.37   | 0.27      | 0.34      | 0.33   | 0.29            | 0.43   | 0.37 |
|        | Difference        | +6%    | +68%      | +3%       | +3%    | +2%             | +2%    | +5%  |
|        | File-level        | 0.37   | 0.32      | 0.38      | 0.31   | 0.31            | 0.50   | 0.39 |
| Medium | Path Distance 16K | 0.43   | 0.49      | 0.42      | 0.44   | 0.44            | 0.58   | 0.49 |
|        | Difference        | +16%   | +53%      | +10%      | +42%   | +42%            | +16%   | +26% |
|        | File-level        | 0.36   | 0.29      | 0.39      | 0.34   | 0.30            | 0.44   | 0.35 |
| Large  | Path Distance 16K | 0.46   | 0.44      | 0.55      | 0.46   | 0.42            | 0.54   | 0.47 |
|        | Difference        | +27%   | +52%      | +41%      | +35%   | +40%            | +23%   | +35% |
|        | File-level        | 0.40   | 0.34      | 0.44      | 0.34   | 0.30            | 0.50   | 0.39 |
| Huge   | Path Distance 16K | 0.44   | 0.43      | 0.54      | 0.41   | 0.40            | 0.54   | 0.45 |
|        | Difference        | +10%   | +26%      | +22%      | +20%   | +36%            | +8%    | +17% |

<span id="page-31-0"></span>Table 9: Results of the project-level code completion for CodeLlama 7B. The metric is Exact Match for the generated line.

### Q43 Are there tasks for which the dataset should not be used?

• We ask users of the datasets not to use the provided data for training.

### <span id="page-31-1"></span>Q44 Any other comments?

- We provide several context composers as baselines.
	- *Naive composer* all the files from the repository snapshot are concatenated into one string with no specific order.
	- *Path distance composer* the order of the files is defined by the distance between files in a project file tree: if the file from the repository is closer to the completion file, then its content is closer in the context.
	- *File length composer* the order of the files is defined by the length of a file: shorter files are closer to the completion file.
	- *Half memory composer* each line from the repository files is removed with a probability of 0.5, and the order of the files is the same as in the naive composer.
	- *Imports first composer* the order of the files is defined by an import relation of first degree: if any project files are imported in the completion file, then these files are closer to the completion file.
	- *Only declarations composer* some project files are left only with declaration lines, so we keep only names from the repository files.
- We leave further exploration of different context composers for future work. We present results for different context composers for CodeLlama 7B and the *mediumcontext* dataset in Table [10.](#page-32-0) Our experiments show that the perplexity values are different, but the order of composers performance is the same. A number in the column name means the maximum number of tokens in the context from the repository snapshot.

### C.6 Distribution

- Q45 Will the dataset be distributed to third parties outside of the entity?
	- Yes, the dataset is publicly available on the internet.
- Q46 How will the dataset be distributed? Does the dataset have a digital object identifier (DOI)?
	- The dataset is available through DOI at the HuggingFace Hub: [https://doi.org/](https://doi.org/10.57967/hf/2512) [10.57967/hf/2512](https://doi.org/10.57967/hf/2512).
- Q47 When will the dataset be distributed?
	- The dataset is already publicly available.
- Q48 Will the dataset be distributed under a copyright or other intellectual property (IP) license, and/or under applicable terms of use (ToU)?

<span id="page-31-2"></span><sup>5</sup>We leave only declarations in all files except for one.

<span id="page-32-0"></span>

| Additional context     | All files |       |        | Only Python files |       |        | Difference with FL |  |
|------------------------|-----------|-------|--------|-------------------|-------|--------|--------------------|--|
|                        | 256       | 1,753 | 12,000 | 256               | 1,753 | 12,000 |                    |  |
| File-level (FL)        | 1.849     | 1.849 | 1.849  | 1.849             | 1.849 | 1.849  | 0.000              |  |
| Naive                  | 1.798     | 1.788 | 1.761  | 1.788             | 1.760 | 1.677  | 0.172              |  |
| Path distance (PD)     | 1.783     | 1.727 | 1.607  | 1.782             | 1.726 | 1.601  | 0.248              |  |
| Half memory (HM)       | 1.799     | 1.789 | 1.743  | 1.789             | 1.765 | 1.670  | 0.179              |  |
| HM + PD                | 1.782     | 1.730 | 1.636  | 1.783             | 1.729 | 1.636  | 0.213              |  |
| File length            | 1.797     | 1.784 | 1.742  | 1.792             | 1.774 | 1.708  | 0.141              |  |
| Imports First          | 1.791     | 1.769 | 1.732  | 1.785             | 1.751 | 1.666  | 0.183              |  |
| Only declaration + PD5 | 1.785     | 1.741 | 1.710  | 1.785             | 1.739 | 1.708  | 0.141              |  |

Table 10: The results for different context composers. The metric is perplexity on the completion file.

- Data coming from GitHub will be re-distributed under the license it was distributed with originally on GitHub (for which we only used permissive licenses). The terms of use require that research conducted with this dataset makes any resulting paper available as open access, in line with GitHub's requirements.
- Q49 Have any third parties imposed IP-based or other restrictions on the data associated with the instances?

• No.

- Q50 Do any export controls or other regulatory restrictions apply to the dataset or to individual instances?
	- To the best of our knowledge, no.
- Q51 Any other comments?
	- No.

### C.7 Maintenance

### Q52 Who is supporting/hosting/maintaining the dataset?

- The dataset will be maintained by the JetBrains Research team.
- Q53 How can the owner/curator/manager of the dataset be contacted (*e.g.*, email address)?
	- The dataset curators can be contacted via email at lca@jetbrains.com.
- Q54 Is there an erratum?
	- There is no erratum as of June 2024.
- Q55 Will the dataset be updated? (*e.g.*, to correct labeling errors, add new instances, delete instances)?
	- The dataset will be extended to more languages and samples over the course of time.
- Q56 If the dataset relates to people, are there applicable limits on the retention of the data associated with the instances?
	- On the HuggingFace Space, we provide information on how individuals can request removals.
- Q57 Will older versions of the dataset continue to be supported/hosted/maintained?
	- The older versions will be kept around for consistency.
- Q58 If others want to extend/augment/build on/contribute to the dataset, is there a mechanism for them to do so?
	- We welcome all contributions and encourage others to contact the dataset curators via the provided email.

### Q59 Any other comments?

• No.

<span id="page-33-1"></span>

| Field   | Description                                                                                                                                                            |
|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| repo    | The full name of the GitHub repository the<br>commit comes from                                                                                                        |
| hash    | The SHA hash of the commit, serves as an<br>identifier inside individual repository                                                                                    |
| date    | The timestamp of the commit (from the<br>commit author)                                                                                                                |
| license | The type of the license in the repository of<br>the commit                                                                                                             |
| message | The ground truth commit message                                                                                                                                        |
| mods    | The changes performed in a commit, rep<br>resented as a list of per-file modifications,<br>where the structure of a per-file modifica<br>tion is described in Table 12 |

Table 11: The structure of datapoints in the commit message generation dataset.

# <span id="page-33-0"></span>D Datasheet for the Commit Message Generation dataset

### D.1 Motivation

### Q1 For what purpose was the dataset created?

• Commit message generation benchmark from Long Code Arena aims to evaluate machine learning models that generate natural language descriptions for large changes in software projects. Prior works on commit message generation typically address smaller changes and do not clean the data to the rigorous standards of manual curation.

### Q2 Who created this dataset (*e.g.*, which team, research group) and on behalf of which entity (*e.g.,* company, institution, organization)?

• This dataset is created by the JetBrains Research team, in particular, by the authors of this paper.

### Q3 Who funded the creation of the dataset?

• This work was conducted at JetBrains Research and therefore was funded by JetBrains, a vendor of specialized development tools.

### Q4 Any other comments?

• No.

### D.2 Composition

### Q5 What do the instances that comprise the dataset represent?

• Each instance in the dataset represents a commit from a GitHub repository, with metadata like commit SHA and full repository name, ground truth commit message, and the list of performed changes in the Git diff format. Also, the dataset includes snapshots of all associated repositories to facilitate context construction.

### Q6 How many instances are there in total (of each type, if appropriate)?

- There are 163 datapoints in total.
- Q7 Does the dataset contain all possible instances or is it a sample (not necessarily random) of instances from a larger set?
	- The dataset is a sample from the test set of the CommitChronicle dataset, which is a vast collection of commits from GitHub repositories.

### Q8 What data does each instance consist of?

- The structure of the datapoints is presented in Table [11.](#page-33-1)
- Q9 Is there a label or target associated with each instance?

<span id="page-34-0"></span>

| Field       | Description                                                                                            |
|-------------|--------------------------------------------------------------------------------------------------------|
| change_type | The type of change to the current file, one<br>of:<br>ADD, COPY, RENAME, DELETE,<br>MODIFY, or UNKNOWN |
| old_path    | The path to file before the change (might<br>be empty if the file was created)                         |
| new_path    | The path to file after change (might be<br>empty if the file was deleted)                              |
| diff        | The changes to the current file, represented<br>in a Git diff format                                   |

Table 12: The structure of a per-file modification in the commit message generation dataset.

• The ground truth commit message for each commit can be regarded as target description for the changes from the corresponding commit.

### Q10 Is any information missing from individual instances?

# • No.

### Q11 Are relationships between individual instances made explicit?

- All instances are independent, yet may share properties such as the same contributor or repository, which are represented as fields in the dataset.
- Q12 Are there recommended data splits (*e.g.*, training, development/validation, testing)?
	- The dataset only contains data for evaluation (*i.e.*, testing split).
- Q13 Are there any errors, sources of noise, or redundancies in the dataset?
	- See preprocessing in [Q35.](#page-36-0)
- Q14 Is the dataset self-contained, or does it link to or otherwise rely on external resources?
	- The dataset is self-contained, as it provides the snapshots of all associated repositories.

### Q15 Does the dataset contain data that might be considered confidential?

• This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained confidential materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered confidential.

### Q16 Does the dataset contain data that, if viewed directly, might be offensive, insulting, threatening, or might otherwise cause anxiety?

• The data comes from GitHub, and hence must comply with GitHub's acceptable use policy, in particular concerning user safety. We also manually verified our data and did not find any violation.

### Q17 Does the dataset relate to people?

• The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.

### Q18 Does the dataset identify any subpopulations (*e.g.*, by age, gender)?

- We do not provide any markers of subpopulations, since people are not the focus of the dataset. However, some indicators might be possible to deduce by following individual datapoints to their source.
- Q19 Is it possible to identify individuals (*i.e.*, one or more natural persons), either directly or indirectly (*i.e.*, in combination with other data) from the dataset?
	- The data was collected from GitHub and thus might be traced back to GitHub users.
- Q20 Does the dataset contain data that might be considered sensitive in any way?

• This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained sensitive materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered sensitive.

### Q21 Any other comments?

• No.

# D.3 Collection

### Q22 How was the data associated with each instance acquired?

- The data associated with each instance was acquired directly from the CommitChronicle dataset [\[13](#page-9-7)].
- Q23 What mechanisms or procedures were used to collect the data (*e.g.*, hardware apparatus or sensor, manual human curation, software program, software API)?
	- We refer the reader to the work of Eliseeva et al. [\[13](#page-9-7)] for the details about data collection. We also perform manual validation to select high-quality examples with long diffs and commit messages.
- Q24 If the dataset is a sample from a larger set, what was the sampling strategy?
	- This dataset is based on the test set of CommitChronicle to leave the disjoint train and validation sets for further experiments. We leave only Python commits from the test set and perform rigorous filtering as described in [Q35.](#page-36-0)

### Q25 Who was involved in the data collection process (*e.g.*, students, crowdworkers, contractors) and how were they compensated?

• The data collection process was conducted by the authors of CommitChronicle, Eliseeva et al. [\[13\]](#page-9-7).

# Q26 Over what timeframe was the data collected?

• The CommitChronicle dataset [\[13\]](#page-9-7) was collected in February 2023. The construction of this dataset took place between October 2023 and January 2024.

### Q27 Were any ethical review processes conducted?

• No.

# Q28 Does the dataset relate to people?

- The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.
- Q29 Did you collect the data from the individuals in question directly, or obtain it via third parties or other sources (*e.g.*, websites)?
	- We collected the data from GitHub, a website hosting code and artifacts written by humans.

### Q30 Were the individuals in question notified about the data collection?

- Individuals were not notified about the data collection, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused.
- Q31 Did the individuals in question consent to the collection and use of their data?
	- We did not ask for consent directly, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused. We made sure our data collection procedure is in line with GitHub's acceptable use policies.
- Q32 If consent was obtained, were the consenting individuals provided with a mechanism to revoke their consent in the future or for certain uses?
	- On our HuggingFace Space, we provide information on how individuals can request removals.

<span id="page-36-1"></span>Table 13: Filters applied to the CommitChronicle subset to build the commit message generation dataset from Long Code Arena. \*Since the *Quality* filter is based on a deep learning classifier, it was applied only to the subset of 3,366 commits obtained by running all the other filters.

|                 | Filter Description | Filter Details                                                                                                      | Number of commits<br>rejected by the filter<br>(% of initial sam<br>ple) |
|-----------------|--------------------|---------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| Diff Filters    | Hash Diffs         | Diff has whitespace-separated character-to-words<br>ratio ≤ 20 [33].                                                | 437 (0.25%)                                                              |
|                 | Modification       | Diff consists only of modifications of existing files<br>(no additions, deletions, renaming, or copying).           | 25,750 (14.95%)                                                          |
|                 | Capitalization     | Message starts with an uppercase letter [44].                                                                       | 68,384 (39.70%)                                                          |
| Message Filters | Verbs              | Message starts with any of the curated set of verbs<br>from the recent work of Muennighoff et al. [44].             | 90,696 (52.66%)                                                          |
|                 | References         | Message does not contain external references<br>(URLs or references to issues/pull requests).                       | 31,487 (18.28%)                                                          |
|                 | Noise              | Message does not follow certain patterns consid<br>ered automatically generated or trivial [13, 44].                | 6,304 (3.66%)                                                            |
|                 | Min Words          | Message<br>contains<br>≥<br>4<br>words<br>(whitespace<br>separated).                                                | 24,474 (14.21%)                                                          |
|                 | Min Lines          | Message contains ≥ 2 lines.                                                                                         | 138,160 (80.22%)                                                         |
|                 | Hash Messages      | Message has whitespace-separated character-to<br>words ratio ≤ 20 [33] and does not contain any<br>SHA hashes [13]. | 12,540 (7.28%)                                                           |
|                 | Quality            | Message is considered good by the commit mes<br>sage quality classifier.                                            | 106 (3.14%)*                                                             |

### Q33 Has an analysis of the potential impact of the dataset and its use on data subjects been conducted?

• Since individuals are not the focus of our dataset, we foresee at most limited impact. Users of the dataset might attempt to trace back artifacts to individuals (via GitHub) and try to reach out to them (via contact information on GitHub) with questions about their artifacts.

### Q34 Any other comments?

• No.

# <span id="page-36-0"></span>D.4 Preprocessing / Cleaning / Labeling

# Q35 Was any preprocessing/cleaning/labeling of the data done?

- The exact data processing steps are listed in Table [13.](#page-36-1) For the commit message quality filter, we refine the dataset released in a recent study from Li and Ahmed [\[32\]](#page-10-17) to make it more suitable for data filtering purposes, and fine-tune the CodeBERT [\[15](#page-9-15)] model. Our commit message quality dataset[6](#page-36-2) and classifier[7](#page-36-3) are available online.
- After filtering, we retain 3,260 commits. Since we aim to target commits with larger changes, after the initial filtering, we only keep samples where the number of characters in diffs related to .py files is ≥ 3,000 characters. That leaves us with 858 commits that we further filter manually.
- The manual labeling is conducted by one of the authors. We employ a 5-point Likert scale and additionally provide comments that elaborate on the reasoning for most of the samples. To facilitate further research, we made all the labels and comments available in the dataset.

### Q36 Was the "raw" data saved in addition to the preprocessed/cleaned/labeled data?

• The raw data about each commit from the repositories included in the final version of our dataset can be obtained from the provided repositories' snapshots.

<span id="page-36-2"></span><sup>6</sup>Commit message quality dataset: [https://huggingface.co/datasets/saridormi/](https://huggingface.co/datasets/saridormi/commit-message-quality) [commit-message-quality](https://huggingface.co/datasets/saridormi/commit-message-quality)

<span id="page-36-3"></span><sup>7</sup>Commit message quality classifier: [https://huggingface.co/saridormi/](https://huggingface.co/saridormi/commit-message-quality-codebert) [commit-message-quality-codebert](https://huggingface.co/saridormi/commit-message-quality-codebert)

### Q37 Is the software used to preprocess/clean/label the instances available?

• The code for preprocessing is available on demand by contacting the authors.

- Q38 Any other comments?
	- No.

### D.5 Uses

### Q39 Has the dataset been used for any tasks already?

• We run multiple instruction-tuned LLMs on the presented commit message generation benchmark in a zero-shot setting (*i.e.*, no examples in the prompt, only a natural language instruction). We employ the same prompt for all models, which we refine to address the most frequent issues in the generated messages from pilot experiments. The prompt is presented in Figure [2.](#page-37-0) We only incorporate commit changes represented as diffs returned by the git diff command to prompt the LLMs and leave collection of more sophisticated contexts for future works. Additionally, we run the CodeT5 [\[60\]](#page-11-8) model fine-tuned for commit message generation task on the training part of the CommitChronicle dataset. This model only takes the commit diff as an input.

Write a commit message for a given diff. Start with a heading that serves as a summary of the whole diff: a single sentence in an imperative form, no more than 50 characters long. If you have details to add, do it after a blank line. Do your best to be specific, do not use 'refactor' unless you are absolutely sure that this change is ONLY a refactoring. Your goal is to communicate what the change does without having to look at the source code. Do not go into low-level details like all the changed files, do not be overly verbose. Avoid adding any external references like issue tags, URLs or emails. Diff:

[DIFF]

Commit message:

<span id="page-37-0"></span>Figure 2: The prompt for the commit message generation task.

• We run each model three times with different random seeds and report average metrics across runs. We access OpenAI models through the official API. For all the other baselines, we use a single NVIDIA A100 GPU with default precision (except for Mixtral, where we use 8-bit precision [\[12\]](#page-8-11)) and FlashAttention-2 [\[11\]](#page-8-1) enabled. For all the models, we set the temperature to 0.8 and allow them to generate up to 512 tokens. This upper bound is mostly set due to practical considerations, as the maximum length of a commit message in our Commit Message Generation dataset is only 58 whitespace-separated words. The results are presented in Table [14.](#page-38-0)

### Q40 Is there a repository that links to any or all papers or systems that use the dataset?

• The dataset is currently used in our repository with baselines available on GitHub.

### Q41 What tasks could the dataset be used for?

• The dataset can be directly employed for the commit message generation task. It might be used for other tasks related to the source code changes.

### Q42 Is there anything about the composition of the dataset or the way it was collected and preprocessed/cleaned/labeled that might impact future uses?

• Not in the data itself. As per the GitHub acceptable usage requirements, researchers using this dataset must make any papers resulting from it available as open access.

### Q43 Are there tasks for which the dataset should not be used?

- To the best of our knowledge, no.
- Q44 Any other comments?
	- No.

<span id="page-38-0"></span>Table 14: Results for the CMG benchmark from Long Code Arena. *R* stands for *ROUGE* metric, *BS* stands for *BERTScore* metric, where *BS (norm.)* is the normalized version. All model categories are sorted by the *ROUGE-1* metric. The best result in the category is highlighted in bold, and the second best result is underlined. \*CodeT5 is the only model fine-tuned for the CMG task as opposed to the zero-shot setting for the rest of the models.

|              | Model                 | BLEU  | ChrF   | R-1    | R-2   | R-L    | BS    | BS<br>(norm.) |
|--------------|-----------------------|-------|--------|--------|-------|--------|-------|---------------|
| Proprietary  | GPT-4 Turbo (1106)    | 2.803 | 34.391 | 26.622 | 5.296 | 17.717 | 0.856 | 0.146         |
|              | GPT-4 (0613)          | 2.127 | 32.624 | 23.497 | 5.217 | 16.033 | 0.852 | 0.124         |
|              | GPT-3.5 Turbo (0613)  | 2.101 | 26.664 | 19.976 | 4.227 | 14.447 | 0.846 | 0.087         |
|              | GPT-3.5 Turbo (1106)  | 1.885 | 20.698 | 18.424 | 3.815 | 14.087 | 0.854 | 0.136         |
| OSS (medium) | Mixtral 8 bit (8x7B)  | 2.189 | 31.984 | 23.61  | 5.376 | 16.329 | 0.848 | 0.097         |
|              | DeepSeek Coder (33B)  | 1.742 | 29.08  | 21.011 | 4.471 | 14.458 | 0.843 | 0.067         |
|              | CodeLLaMA (34B)       | 1.586 | 24.632 | 17.817 | 3.684 | 13.114 | 0.844 | 0.073         |
| OSS (small)  | Mistral (7B)          | 1.895 | 30.719 | 23.648 | 4.458 | 16.262 | 0.847 | 0.096         |
|              | DeepSeek Coder (6.7B) | 1.634 | 28.567 | 20.188 | 3.604 | 14.116 | 0.843 | 0.068         |
|              | CodeLLaMA (13B)       | 1.727 | 23.099 | 18.207 | 3.642 | 13.479 | 0.844 | 0.075         |
|              | CodeLLaMA (7B)        | 1.108 | 26.638 | 16.961 | 2.807 | 12.028 | 0.835 | 0.021         |
| OSS (tiny)   | DeepSeek Coder (1.3B) | 0.75  | 22.449 | 13.815 | 2.029 | 9.753  | 0.822 | -0.057        |
|              | CodeT5* (220M)        | 0.355 | 11.862 | 13.615 | 2.633 | 11.439 | 0.845 | 0.083         |

### D.6 Distribution

### Q45 Will the dataset be distributed to third parties outside of the entity?

- Yes, the dataset is publicly available on the internet.
- Q46 How will the dataset be distributed? Does the dataset have a digital object identifier (DOI)?
	- The dataset is available through DOI at the HuggingFace Hub: [https://doi.org/](https://doi.org/10.57967/hf/2513) [10.57967/hf/2513](https://doi.org/10.57967/hf/2513).

### Q47 When will the dataset be distributed?

• The dataset is already publicly available.

### Q48 Will the dataset be distributed under a copyright or other intellectual property (IP) license, and/or under applicable terms of use (ToU)?

- Data coming from GitHub will be re-distributed under the license it was distributed with originally on GitHub (for which we only used permissive licenses). The terms of use require that research conducted with this dataset makes any resulting paper available as open access, in line with GitHub's requirements.
- Q49 Have any third parties imposed IP-based or other restrictions on the data associated with the instances?

• No.

- Q50 Do any export controls or other regulatory restrictions apply to the dataset or to individual instances?
	- To the best of our knowledge, no.
- Q51 Any other comments?
	- No.

### D.7 Maintenance

### Q52 Who is supporting/hosting/maintaining the dataset?

- The dataset will be maintained by the JetBrains Research team.
- Q53 How can the owner/curator/manager of the dataset be contacted (*e.g.*, email address)?
	- The dataset curators can be contacted via email at lca@jetbrains.com.
- Q54 Is there an erratum?
	- There is no erratum as of June 2024.
- Q55 Will the dataset be updated? (*e.g.*, to correct labeling errors, add new instances, delete instances)?
	- The dataset will be extended to more languages and samples over the course of time.
- Q56 If the dataset relates to people, are there applicable limits on the retention of the data associated with the instances?
	- On the HuggingFace Space, we provide information on how individuals can request removals.
- Q57 Will older versions of the dataset continue to be supported/hosted/maintained?
	- The older versions will be kept around for consistency.
- Q58 If others want to extend/augment/build on/contribute to the dataset, is there a mechanism for them to do so?
	- We welcome all contributions and encourage others to contact the dataset curators via the provided email.
- Q59 Any other comments?
	- No.

# <span id="page-39-0"></span>E Datasheet for the Bug Localization dataset

### E.1 Motivation

- Q1 For what purpose was the dataset created?
	- The bug localization benchmark is a part of the Long Code Arena that serves to evaluate models' abilities in locating files that should be changed given a bug description. The dataset includes real issues that describe bugs, together with the respective pull requests (PRs) that fix them. The model under evaluation takes a bug description and the repository state before the fix and then outputs the list of files that need to be changed.
- Q2 Who created this dataset (*e.g.*, which team, research group) and on behalf of which entity (*e.g.,* company, institution, organization)?
	- This dataset is created by the JetBrains Research team, in particular, by the authors of this paper.

### Q3 Who funded the creation of the dataset?

- This work was conducted at JetBrains Research and therefore was funded by JetBrains, a vendor of specialized development tools.
- Q4 Any other comments?
	- No.

### E.2 Composition

### Q5 What do the instances that comprise the dataset represent?

• Each datapoint contains three key elements: the bug description, the state of the repository where the bug is reproducible, and the list of files that need to be modified to resolve the bug. The bug description represents the body of the issue that was assigned a bug-related label. The repository state is represented by the commit SHA. The list of files that should be modified comes from the pull request that resolves the respective bug report.

### Q6 How many instances are there in total (of each type, if appropriate)?

- The dataset contains 7,479 datapoints in total divided, between three sets by language: – py — change contains only Python files (4,339 datapoints);
	- java change contains only Java files (2,522 datapoints);

| Field          | Description                                                                                           |
|----------------|-------------------------------------------------------------------------------------------------------|
| id             | Datapoint ID                                                                                          |
| repo_owner     | Bug issue repository owner                                                                            |
| repo_name      | Bug issue repository name                                                                             |
| static_id      | Datapoint text ID                                                                                     |
| issue_url      | GitHub link to issue                                                                                  |
| issue_title    | Issue title                                                                                           |
| issue_body     | Issue body with bug description                                                                       |
| issue_labels   | List of labels assigned to issue                                                                      |
| pull_url       | GitHub link to PR                                                                                     |
| pull_create_at | Date of PR creation in format of yyyy-mm-ddThh:mm:ssZ                                                 |
| base_sha       | PR base SHA                                                                                           |
| head_sha       | PR head SHA                                                                                           |
| diff_url       | PR diff URL between base and head SHA                                                                 |
| diff           | PR diff content                                                                                       |
| changed_files  | List of changed files parsed from diff                                                                |
| link_url       | GitHub link to issue or PR comment from which the link was<br>parsed                                  |
| links_count    | Number of links between the issue and the PR, equals 2 if the<br>link is mutual, 1 if it is one-sided |
| link_keyword   | "Fix"-related keyword which surrounds the issue link                                                  |
| stars          | Number of repository stars                                                                            |
| language       | Main programming language for repository                                                              |

<span id="page-40-0"></span>Table 15: Description of datapoints in the bug localization dataset.

– kt — change contains only Kotlin files (618 datapoints).

50 datapoints for each language are manually verified in order to form a test subset for model evaluation (150 datapoints in total).

### Q7 Does the dataset contain all possible instances or is it a sample (not necessarily random) of instances from a larger set?

• The dataset is a sample. It comes from a larger set of issues in Python, Kotlin, and Java GitHub repositories.

### Q8 What data does each instance consist of?

- The core fields in the datapoints are presented in Table [15.](#page-40-0)
- Based on the core fields, we calculated the number of statistics and attached them to each datapoint. The additional fields are presented in Table [16.](#page-41-0) We excluded test files from the experiment because their modifications typically only support program repairs and do not contain the actual bugs. Thus, all metrics are calculated on all project files except for the test files.

### Q9 Is there a label or target associated with each instance?

• The target for the bug localization task is the list of files that should be changed (field changed\_files in the dataset).

### Q10 Is any information missing from individual instances?

• No.

### Q11 Are relationships between individual instances made explicit?

• All instances are independent, yet may share properties such as the same contributor or repository, which are represented as fields in the dataset.

### Q12 Are there recommended data splits (*e.g.*, training, development/validation, testing)?

- The dataset contains the dedicated test split consisting of 150 examples that are manually verified for correctness. Along with it, we present a development split that was not manually checked but can be used by researchers for model development.
- Q13 Are there any errors, sources of noise, or redundancies in the dataset?

| Metric                                  | Description                                                                  |
|-----------------------------------------|------------------------------------------------------------------------------|
| issue_symbols_count                     | Number of symbols in issue description                                       |
| issue_tokens_count<br>issue_words_count | Number of tokens in issue description                                        |
| issue_lines_count                       | Number of words in issue description<br>Number of lines in issue description |
| issue_code_blocks_count                 | Number of triple quotes blocks parsed in                                     |
|                                         | issue description                                                            |
| issue_links_count                       | Number of links parsed in issue description                                  |
| diff_symbols_count                      | Number of symbols in diff                                                    |
| diff_tokens_count                       | Number of tokens in diff                                                     |
| diff_words_count                        | Number of words in diff                                                      |
| issue_lines_count                       | Number of lines in diff                                                      |
| changed_files_count                     | Number of all changed files mentioned in<br>diff                             |
| changed_files_without_test_count        | Number of changed files not including test<br>files mentioned in diff        |
| code_changed_files_count                | Number of files written in Python, Java, or<br>Kotlin mentioned in diff      |
| py_changed_files_count                  | Number<br>of<br>Python<br>files<br>mentioned<br>as<br>changed in diff        |
| java_changed_files_count                | Number of Java files mentioned as changed<br>in diff                         |
| kt_changed_files_count                  | Number<br>of<br>Kotlin<br>files<br>mentioned<br>as<br>changed in diff        |
| repo_symbols_count                      | Total number of symbols in repository's<br>files                             |
| repo_tokens_count                       | Total number of tokens in repository's<br>files.                             |
| repo_words_count                        | Total number of words in repository's files                                  |
| repo_lines_count                        | Total number of lines in repository's files                                  |
| repo_files_count                        | Total number of files in repository                                          |
| repo_files_without_test_count           | Total number of files without tests in the<br>repository                     |

<span id="page-41-0"></span>Table 16: Description of additional metrics calculated on the bug localization dataset.

• We describe the data collection process in [Q22.](#page-42-0)

### Q14 Is the dataset self-contained, or does it link to or otherwise rely on external resources?

• The dataset does not store the repository snapshots but rather fetches them from GitHub during benchmarking to reduce the dataset's memory requirements.

### Q15 Does the dataset contain data that might be considered confidential?

• This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained confidential materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered confidential.

### Q16 Does the dataset contain data that, if viewed directly, might be offensive, insulting, threatening, or might otherwise cause anxiety?

• The data comes from GitHub, and hence must comply with GitHub's acceptable use policy, in particular concerning user safety. We also manually verified our data and did not find any violation.

### Q17 Does the dataset relate to people?

• The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.

### Q18 Does the dataset identify any subpopulations (*e.g.*, by age, gender)?

- We do not provide any markers of subpopulations, since people are not the focus of the dataset. However, some indicators might be possible to deduce by following individual datapoints to their source.
- Q19 Is it possible to identify individuals (*i.e.*, one or more natural persons), either directly or indirectly (*i.e.*, in combination with other data) from the dataset?
	- The data was collected from GitHub and thus might be traced back to GitHub users.

### Q20 Does the dataset contain data that might be considered sensitive in any way?

• This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained sensitive materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered sensitive.

### Q21 Any other comments?

• No.

### <span id="page-42-0"></span>E.3 Collection

### Q22 How was the data associated with each instance acquired?

- To collect the data, we use the following protocol:
	- (a) We start with the common corpus of collected GitHub repositories. Then, for each repository, we download information about all issues, pull requests, and comments using the GitHub API. As a result, we download more than 8M issues, 7M pull requests, and 34.4M comments.
	- (b) GitHub API does not provide information about relations between issues and pull requests. We obtain these relations by parsing references from descriptions or comments. To do so, we write regular expressions for extracting all possible referencing formats as provided in GitHub documentation. To also collect the context around the reference, we capture one "fix"-related keyword (*e.g.*, close, closes, closed, fix, fixes, fixed, resolve, resolves, resolved, solve, solves, solved) before and after the link with the regular expressions. We also check if references are mutual (if the issue refers to the pull request and vice versa) or not (if only a single link from either the issue or the pull request exists).
	- (c) We sort all issue-PR pairs by the number of stars in the respective repository and assign each pair an ID based on its index in the sorted order. We populate the diff field by running a git command in a locally cloned repository to get the diff in a text format. Unfortunately, this method does not work for pull requests created from forks, so we save a null value for such cases.
- Q23 What mechanisms or procedures were used to collect the data (*e.g.*, hardware apparatus or sensor, manual human curation, software program, software API)?
	- The data collection step used GitHub API. Then, we performed manual verification and assessment to select and filter data.
- Q24 If the dataset is a sample from a larger set, what was the sampling strategy?
	- The dataset is sampled from a larger set of issues and pull requests as described in [Q22.](#page-42-0)
- Q25 Who was involved in the data collection process (*e.g.*, students, crowdworkers, contractors) and how were they compensated?
	- The data collection process was conducted by the authors of this paper.
- Q26 Over what timeframe was the data collected?
	- The construction of this dataset took place between October 2023 and January 2024.
- Q27 Were any ethical review processes conducted?

• No.

### Q28 Does the dataset relate to people?

- The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.
- Q29 Did you collect the data from the individuals in question directly, or obtain it via third parties or other sources (*e.g.*, websites)?
	- We collected the data from GitHub, a website hosting code and artifacts written by humans.

### Q30 Were the individuals in question notified about the data collection?

• Individuals were not notified about the data collection, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused.

### Q31 Did the individuals in question consent to the collection and use of their data?

- We did not ask for consent directly, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused. We made sure our data collection procedure is in line with GitHub's acceptable use policies.
- Q32 If consent was obtained, were the consenting individuals provided with a mechanism to revoke their consent in the future or for certain uses?
	- On our HuggingFace Space, we provide information on how individuals can request removals.
- Q33 Has an analysis of the potential impact of the dataset and its use on data subjects been conducted?
	- Since individuals are not the focus of our dataset, we foresee at most limited impact. Users of the dataset might attempt to trace back artifacts to individuals (via GitHub) and try to reach out to them (via contact information on GitHub) with questions about their artifacts.
- Q34 Any other comments?
	- No.

### E.4 Preprocessing / Cleaning / Labeling

### Q35 Was any preprocessing/cleaning/labeling of the data done?

- To enhance the quality of our data, first, we apply empirical filters based on the fields from the dataset, as listed in Table [17.](#page-44-0) Firstly, we retain only issues with "bug" mentioned in the labels and non-empty descriptions. Additionally, we remove issues containing links to media, as they may include crucial data visualizations that are inaccessible through other means. To ensure that most models can use the dataset for evaluation, we only keep issues written in English. For pull requests, we filter out those introducing new files and retain only pull requests modifying existing files, provided their diffs could be extracted from the cloned repository. Furthermore, to facilitate the future manual labeling process, we leave only pull requests written in Python, Java, or Kotlin, as these are languages known well to authors. To work with diffs and patches, as well as to extract the changed files and their modification modes, we use the unidiff package.[8](#page-43-0) Additionally, we avoid pull requests that include changes to media files with non-UTF-8 encoding, as such changes are often difficult to reproduce. The most crucial filter ensures that each pull request is associated with exactly one issue, and vice versa, to maintain the relevance of changes to issue descriptions and to prevent situations where a pull request addresses multiple issues or an issue is fixed by several pull requests. Following these filtration steps, 10,195 datapoints remain in the dataset.
- On top of the previous filtering step, we remove outliers for several numerical fields, including changed\_files\_count, changed\_lines\_count, and issue\_tokens\_count. Table [18](#page-44-1) shows the result of removing outliers.

<span id="page-43-0"></span><sup>8</sup>Undiff: <https://pypi.org/project/unidiff/>

| Field        | Description                                                                                      | Number<br>of<br>data<br>points<br>rejected<br>by<br>the filter (% of the<br>initial set) |
|--------------|--------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| issue_labels | At least one label should include "bug" as a sub<br>string                                       | 3,472,057 (79.8%)                                                                        |
| issue_body   | Description should not be empty                                                                  | 16,265 (0.37%)                                                                           |
| issue_body   | Description should contain only text without at<br>tached media                                  | 145,225 (3.34%)                                                                          |
| issue_body   | Description should be written mostly in English                                                  | 35,942 (0.83%)                                                                           |
| diff         | Diff can be extracted and should not be empty or<br>corrupted                                    | 475,447 (10.93%)                                                                         |
| diff         | Diff should consist only of modifications of exist<br>ing files and no introduction of new files | 30,572 (0.7%)                                                                            |
| diff         | Diff should include at least one file in either<br>Python, Java, or Kotlin                       | 138,653 (3.19%)                                                                          |
| diff         | Diff should include only UTF-8 files to filter out<br>unreadable or graphical objects            | 18 (≤ 0.01%)                                                                             |
| base_commit  | Repository content on base commit can be ex<br>tracted and should not be empty or corrupted      | 6,198 (0.14%)                                                                            |
| pull_url     | PR should refer to no more than one issue                                                        | 7,376 (0.17%)                                                                            |
| issue_url    | Issue should refer to no more than one pull request                                              | 1,934 (0.04%)                                                                            |
| link_keyword | "fix"-related keyword should stay before or after<br>link in the issue description.              | 10,406 (0.24%)                                                                           |

<span id="page-44-0"></span>Table 17: Empirical filters applied to the bug localization dataset.

<span id="page-44-1"></span>Table 18: Outlier filters applied to the bug localization dataset.

| Field               | Description                                                                   | Number<br>of<br>data<br>points<br>rejected<br>by<br>the<br>filter<br>(%<br>of<br>initial set) |
|---------------------|-------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| changed_files_count | Number of changed files should not be more than<br>22 (0.99 quantile)         | 100 (≤ 0.01%)                                                                                 |
| changed_lines_count | Number of changed lines should not be more than<br>594 (0.99 quantile)        | 102 (≤ 0.01%)                                                                                 |
| issue_tokens_count  | Issue description can be tokenized using GPT-4 to<br>kenizer                  | 43 (≤ 0.01%)                                                                                  |
| issue_tokens_count  | Issue description should contain at least 13 tokens<br>(0.01 quantile)        | 85 (≤ 0.01%)                                                                                  |
| issue_tokens_count  | Issue description should contain no more than<br>4,500 tokens (0.99 quantile) | 103 (≤ 0.01%)                                                                                 |

- After data filtration, we are left with 7,479 datapoints that comprise the entire dataset. Table [19](#page-45-0) presents statistics of the dataset, with the difference in statistics between languages being negligible.
- After the analysis of the dataset, we carry out manual data labeling and verification process to select the subset of high-quality datapoints for evaluation. First, we sort the datapoints by the number of stars in the respective repositories, assuming that popular repositories have better processes and quality for issue tracking and bug reporting. Then, we go through datapoints of each repository, selecting ones that meet the following criteria:
	- The issue describes a single bug completely and exhaustively.
	- The pull request is linked to the issue and resolves this issue alone.

| Field                   | Min | Median  | Mean      | Max         |
|-------------------------|-----|---------|-----------|-------------|
| repo_files_count        | 16  | 331     | 1,077     | 33,644      |
| repo_lines_count        | 9   | 52,743  | 145,377   | 8,687,912   |
| repo_tokens_count       | 78  | 488,286 | 1,684,619 | 225,649,725 |
| changed_files_count     | 1   | 1       | 2         | 21          |
| changed_lines_count     | 1   | 15      | 37        | 594         |
| changed_tokens_count    | 1   | 158     | 608       | 837,626     |
| issue_words_count       | 1   | 106     | 149       | 1,806       |
| issue_lines_count       | 1   | 22      | 33        | 586         |
| issue_tokens_count      | 13  | 227     | 432       | 4,491       |
| issue_links_count       | 0   | 0       | 0.80      | 56          |
| issue_code_blocks_count | 0   | 1       | 0.99      | 31          |

<span id="page-45-0"></span>Table 19: Final statistics of the dataset.

– All changes are relevant to the described issue, with no extra functionality or side refactorings included.

- The changes were reviewed and accepted.
- If a datapoint does not meet these criteria, we go to another one from the same repository, or if none are left, we move on to the next repository by the number of stars, until we select 50 good datapoints per language. To keep the distribution of the number of changed files, for each repository, we try to pick one datapoint with a single changed file and one datapoint with two or more changed files. This strategy allows us to collect a diverse set of datapoints from different repositories and keep the distribution of the number of changed files similar to the complete set of issues.

### Q36 Was the "raw" data saved in addition to the preprocessed/cleaned/labeled data?

• No.

### Q37 Is the software used to preprocess/clean/label the instances available?

- The code for preprocessing is available on demand by contacting the authors.
- Q38 Any other comments?
	- No.

### E.5 Uses

### Q39 Has the dataset been used for any tasks already?

- We run several baseline solutions on the bug localization task that utilize the presented dataset. The results are presented in Table [20.](#page-46-0)
- First, we evaluate several retrieval-based approaches. The logic is straightforward: data analysis indicates that issue descriptions often include code blocks and stack traces pointing to the code responsible for bugs. Consequently, these descriptions should closely match the content of the files that require modification. Following this logic, we can compute embeddings for the bug report and all project files, and then identify project files that require fixing as the closest to the bug description by the cosine distance in the embedding space. We try several approaches to compute embeddings: TF-IDF with a BPE tokenizer pre-trained on the repository code, CodeT5 [\[60\]](#page-11-8), CodeBERT [\[15](#page-9-15)], GTE [\[34\]](#page-10-10), and Mistral [\[26\]](#page-9-10) models. Also, we evaluate BM25 [\[48\]](#page-10-5), a classic approach from the information retrieval field.
- Second, we evaluate GPT-3.5 and GPT-4, prompting them to identify one to five bugged files using the bug description and the list of repository files. Figure [3](#page-46-1) presents the full prompt with placeholders. If the prompt exceeds the context size, we divide the file list into several queries. The final query combines all outputs and requests the final list sorted by relevance.
- For metrics, we calculate Recall@1 for the datapoints with one changed file, Recall@2 and Precision@2 for datapoints with two or more changed files. For all datapoints, we

```
List of files: [FILES_LIST]
Issue: [ISSUE_TITLE] [ISSUE_DESCRIPTION]
You are given a list of files in the project and a bug issue
description. Select a subset of 1--5 files that SHOULD be fixed
according to the issue. Provide output in JSON format with one field
'files' which contains a list of file names that SHOULD be fixed.
Provide ONLY JSON without any additional comments.
```
<span id="page-46-1"></span>Figure 3: Prompt for bug localization by GPT models.

| Model       | R@1  | R@2  | P@2  | F1-score | MAP  |
|-------------|------|------|------|----------|------|
| TF-IDF+NLTK | 0.16 | 0.1  | 0.15 | 0.13     | 0.20 |
| TF-IDF+BPE  | 0.30 | 0.15 | 0.24 | 0.21     | 0.28 |
| BM25        | 0.17 | 0.12 | 0.19 | 0.19     | 0.21 |
| CodeT5      | 0.28 | 0.13 | 0.17 | 0.18     | 0.23 |
| CodeBERT    | 0.29 | 0.15 | 0.18 | 0.20     | 0.25 |
| GTE         | 0.37 | 0.17 | 0.26 | 0.25     | 0.33 |
| Mistral     | 0.35 | 0.17 | 0.24 | 0.25     | 0.30 |
| GPT-3.5     | 0.49 | 0.19 | 0.31 | 0.35     | 0.29 |
| GPT-4       | 0.74 | 0.20 | 0.32 | 0.44     | 0.39 |

<span id="page-46-0"></span>Table 20: The baseline results for the bug localization task.

also calculate the F1-score and MAP, which we consider the target metric for model comparison.

### Q40 Is there a repository that links to any or all papers or systems that use the dataset?

• The dataset is currently used in our repository with baselines available on GitHub.

### Q41 What tasks could the dataset be used for?

- The provided dataset can be used for evaluating bug localization approaches and other tasks related to bug-fixing problems.
- Q42 Is there anything about the composition of the dataset or the way it was collected and preprocessed/cleaned/labeled that might impact future uses?
	- Not in the data itself. As per the GitHub acceptable usage requirements, researchers using this dataset must make any papers resulting from it available as open access.

### Q43 Are there tasks for which the dataset should not be used?

- To the best of our knowledge, no.
- Q44 Any other comments?
	- No.

### E.6 Distribution

- Q45 Will the dataset be distributed to third parties outside of the entity?
	- Yes, the dataset is publicly available on the internet.
- Q46 How will the dataset be distributed? Does the dataset have a digital object identifier (DOI)?
	- The dataset is available through DOI at the HuggingFace Hub: [https://doi.org/](https://doi.org/10.57967/hf/2514) [10.57967/hf/2514](https://doi.org/10.57967/hf/2514).
- Q47 When will the dataset be distributed?
	- The dataset is already publicly available.
- Q48 Will the dataset be distributed under a copyright or other intellectual property (IP) license, and/or under applicable terms of use (ToU)?
- Data coming from GitHub will be re-distributed under the license it was distributed with originally on GitHub (for which we only used permissive licenses). The terms of use require that research conducted with this dataset makes any resulting paper available as open access, in line with GitHub's requirements.
- Q49 Have any third parties imposed IP-based or other restrictions on the data associated with the instances?

• No.

- Q50 Do any export controls or other regulatory restrictions apply to the dataset or to individual instances?
	- To the best of our knowledge, no.
- Q51 Any other comments?

• No.

### E.7 Maintenance

- Q52 Who is supporting/hosting/maintaining the dataset?
	- The dataset will be maintained by the JetBrains Research team.
- Q53 How can the owner/curator/manager of the dataset be contacted (*e.g.*, email address)?
	- The dataset curators can be contacted via email at lca@jetbrains.com.
- Q54 Is there an erratum?
	- There is no erratum as of June 2024.
- Q55 Will the dataset be updated? (*e.g.*, to correct labeling errors, add new instances, delete instances)?
	- The dataset will be extended to more languages and samples over the course of time.
- Q56 If the dataset relates to people, are there applicable limits on the retention of the data associated with the instances?
	- On the HuggingFace Space, we provide information on how individuals can request removals.
- Q57 Will older versions of the dataset continue to be supported/hosted/maintained?
	- The older versions will be kept around for consistency.
- Q58 If others want to extend/augment/build on/contribute to the dataset, is there a mechanism for them to do so?
	- We welcome all contributions and encourage others to contact the dataset curators via the provided email.
- Q59 Any other comments?

• No.

# <span id="page-47-0"></span>F Datasheet for the Module Summarization dataset

### F.1 Motivation

- Q1 For what purpose was the dataset created?
	- Module summarization dataset is a part of the Long Code Arena that aims at testing models in generating documentation files. The minimal set of data for the task consists of an intent behind the documentation and the relevant part of the codebase. Based on the provided data, the model has to generate the documentation. The testing then happens by running an LLM assessor to decide which documentation is better: the generated one or the ground truth.
- Q2 Who created this dataset (*e.g.*, which team, research group) and on behalf of which entity (*e.g.,* company, institution, organization)?

<span id="page-48-0"></span>

| Field                 | Description                                                                                          |  |  |
|-----------------------|------------------------------------------------------------------------------------------------------|--|--|
| repo                  | The full name of the GitHub repository the<br>commit comes from                                      |  |  |
| docfile_name          | The name of the documentation file. May<br>be useful in the prompt                                   |  |  |
| intent                | Small manually gathered intent that de<br>scribes what we expect from the generated<br>documentation |  |  |
| license               | The type of the license in the repository of<br>the commit                                           |  |  |
| path_to_docfile       | The path to file with documentation in the<br>repository                                             |  |  |
| relevant_code_files   | List of paths in the repository to the poten<br>tially relevant code files                           |  |  |
| relevant_code_dir     | Directory with relevant code, field can be<br>empty                                                  |  |  |
| target_text           | The text of the target documentation —<br>ground truth in our task                                   |  |  |
| relevant_code_context | Code context joined from relevant code<br>files and directories                                      |  |  |

Table 21: The structure of datapoints in the module summarization dataset.

• This dataset is created by the JetBrains Research team, in particular, by the authors of this paper.

### Q3 Who funded the creation of the dataset?

• This work was conducted at JetBrains Research and therefore was funded by JetBrains, a vendor of specialized development tools.

### Q4 Any other comments?

• No.

### F.2 Composition

### Q5 What do the instances that comprise the dataset represent?

- Each instance in the dataset represents an instruction for generating a documentation file (intent and name of the original file), as well as a snapshot of a repository that the model should use for generation. Table [21](#page-48-0) shows the detailed structure of the datapoints.
- Q6 How many instances are there in total (of each type, if appropriate)?
	- There are 216 datapoints in total.
- Q7 Does the dataset contain all possible instances or is it a sample (not necessarily random) of instances from a larger set?
	- The dataset is a sample. It comes from a larger set of Python repositories.
- Q8 What data does each instance consist of?
	- The structure of the datapoints is presented in Table [21.](#page-48-0)
- Q9 Is there a label or target associated with each instance?
	- The target for each instance is the ground truth documentation text.
- Q10 Is any information missing from individual instances?

• No.

- Q11 Are relationships between individual instances made explicit?
	- All instances are independent, yet may share properties such as the same contributor or repository, which are represented as fields in the dataset.
- Q12 Are there recommended data splits (*e.g.*, training, development/validation, testing)?
	- The dataset only contains data for evaluation (*i.e.*, testing split).
- Q13 Are there any errors, sources of noise, or redundancies in the dataset?
	- See collection steps in [Q22.](#page-49-0)
- Q14 Is the dataset self-contained, or does it link to or otherwise rely on external resources?
	- The dataset is self-contained, as it provides the snapshots of all associated repositories.
- Q15 Does the dataset contain data that might be considered confidential?
	- This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained confidential materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered confidential.

### Q16 Does the dataset contain data that, if viewed directly, might be offensive, insulting, threatening, or might otherwise cause anxiety?

• The data comes from GitHub, and hence must comply with GitHub's acceptable use policy, in particular concerning user safety. We also manually verified our data and did not find any violation.

### Q17 Does the dataset relate to people?

• The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.

### Q18 Does the dataset identify any subpopulations (*e.g.*, by age, gender)?

- We do not provide any markers of subpopulations, since people are not the focus of the dataset. However, some indicators might be possible to deduce by following individual datapoints to their source.
- Q19 Is it possible to identify individuals (*i.e.*, one or more natural persons), either directly or indirectly (*i.e.*, in combination with other data) from the dataset?
	- The data was collected from GitHub and thus might be traced back to GitHub users.
- Q20 Does the dataset contain data that might be considered sensitive in any way?
	- This dataset was collected from openly available GitHub repositories with permissive licenses, with the assumption that any data found was intended to be shared freely. However, it is possible that these repositories contained sensitive materials. The data in the dataset was manually evaluated, and we did not see anything that could be considered sensitive.
- Q21 Any other comments?
	- No.

### <span id="page-49-0"></span>F.3 Collection

### Q22 How was the data associated with each instance acquired?

- To collect the data, we use the following protocol:
	- (a) We start with the Python subset of the common corpus of GitHub repositories. For each repository, we extract documentation files — files with extensions .md, .txt, and .rst, located in the docs directory of the repository.
	- (b) For each documentation file, we extract the associated source code. To do this, we parse the target documentation and extract names of all code files and directories mentioned in it. If a file does not contain any such mentions, we skip it.
	- (c) To further filter the documentation files, we convert documentation into a plain text format by removing specific Markdown syntax (as well as text between Markdown tags like *code*, *autosummary*, etc.). We then ensure that each document contains valuable information and has at least 10 lines of text remaining after cleaning.

Since the filtering is quite strict, we believe that only important documents remain after this stage.

- (d) We perform manual review of the datapoints to ensure that the content contains not only information about the code but also summarizes the entire module or project. After manual review, we leave 216 out of 461 files. Most of the files that we reject contain non-informative text that is not related to code. Also, for each documentation file, we manually specify an intent that the model under evaluation can use during generation.
- Manual verification is essential, as our experience with data frequently reveals instances where a docfile lacks useful content or does not provide substantial information in the plain text format, without special extensions that enrich documentation.
- Q23 What mechanisms or procedures were used to collect the data (*e.g.*, hardware apparatus or sensor, manual human curation, software program, software API)?
	- The data collection step used GitHub API. Then, we performed manual verification and assessment to select and filter data.

### Q24 If the dataset is a sample from a larger set, what was the sampling strategy?

- The dataset is sampled from a larger set of repositories by selecting only repositories with Python as the main language and further filtering as described in [Q22.](#page-49-0)
- Q25 Who was involved in the data collection process (*e.g.*, students, crowdworkers, contractors) and how were they compensated?
	- The data collection process was conducted by the authors of this paper.
- Q26 Over what timeframe was the data collected?
	- The construction of this dataset took place between October 2023 and January 2024.
- Q27 Were any ethical review processes conducted?
	- No.
- Q28 Does the dataset relate to people?
	- The dataset consists of code and artifacts collected from GitHub, meaning that they were written by human users. However, these human users themselves, their coding style, authorship information, authorship of source code in any other way, or personal information in any other way are not the focus of the dataset directly.
- Q29 Did you collect the data from the individuals in question directly, or obtain it via third parties or other sources (*e.g.*, websites)?
	- We collected the data from GitHub, a website hosting code and artifacts written by humans.
- Q30 Were the individuals in question notified about the data collection?
	- Individuals were not notified about the data collection, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused.
- Q31 Did the individuals in question consent to the collection and use of their data?
	- We did not ask for consent directly, however, we made sure to only collect the data with permissive licenses, ensuring that it can be reused. We made sure our data collection procedure is in line with GitHub's acceptable use policies.
- Q32 If consent was obtained, were the consenting individuals provided with a mechanism to revoke their consent in the future or for certain uses?
	- On our HuggingFace Space, we provide information on how individuals can request removals.
- Q33 Has an analysis of the potential impact of the dataset and its use on data subjects been conducted?
	- Since individuals are not the focus of our dataset, we foresee at most limited impact. Users of the dataset might attempt to trace back artifacts to individuals (via GitHub) and try to reach out to them (via contact information on GitHub) with questions about their artifacts.

### Q34 Any other comments?

• No.

### F.4 Preprocessing / Cleaning / Labeling

- Q35 Was any preprocessing/cleaning/labeling of the data done?
	- The data filtering, preprocessing, and labeling steps are described in the data collection procedure in [Q22.](#page-49-0)
- Q36 Was the "raw" data saved in addition to the preprocessed/cleaned/labeled data?

• No.

- Q37 Is the software used to preprocess/clean/label the instances available?
	- The code for preprocessing is available on demand by contacting the authors.
- Q38 Any other comments?

• No.

### F.5 Uses

### Q39 Has the dataset been used for any tasks already?

• We run several LLMs on the collected module summarization dataset with different length of the relevant code context. To assess the quality of the generated documentation, we introduce a new metric called CompScore that uses LLM (Mistral-7B in our case) as an assessor. CompScore feeds the assessor LLM relevant code and two versions of documentation: the ground truth and the model-generated text. The LLM then evaluates which documentation better explains and fits the code. To mitigate variance and potential ordering effects in model responses, we calculate the probability that the generated documentation is superior by averaging the results of two queries:

$$\text{CompScore} = \frac{P(\text{pred} \mid \text{LLM}(\text{code}, \text{pred}, \text{gold})) + P(\text{pred} \mid \text{LLM}(\text{code}, \text{gold}, \text{pred}))}{2}$$

To count P(pred | LLM(code, pred, gold)), we follow several steps:

(a) Construct the prompt and feed it into the assessor LLM (see Figure [4\)](#page-51-0).

I have 2 different documentations about {intent}. Decide which documentation is better: documentation A or documentation B. My code: [TRIMMED\_CODE\_CONTEXT] Documentation A: [PREDICTED\_DOC] Documentation B: [GROUND\_TRUTH\_DOC] Better documentation is documentation

<span id="page-51-0"></span>Figure 4: Prompt for the CompScore metric.

(b) Get logits for the next token being "A" and "B" (logit<sup>A</sup> and logitB) and convert them into probabilities:

probA, prob<sup>B</sup> = exp (log\_sof tmax([logitA, logitB]))

- (c) P(pred | LLM(code, pred, gold)) = prob<sup>A</sup> shows the probabilty that the predicted documentation is better than the original from the perspective of the LLM assessor.
- For our experiments, we use Mistral-7B-Instruct-v0.2 as LLM assessor. We truncate relevant code up to 6,000 tokens in the prompt for metric computation. We evaluate all the models presented in Table [22](#page-52-0) via OpenAI API or TogetherAI API with the same generation parameters. We use zero temperature and predict up to 2,000 new tokens without any penalties to get deterministic results during generation. Table [22](#page-52-0) shows the results for all the evaluated LLMs with varying length of available relevant code context.

<span id="page-52-0"></span>

| Model           | 128 tokens | 512 tokens | 1k tokens | 2k tokens |
|-----------------|------------|------------|-----------|-----------|
| Mistral-7B-v0.3 | 35.84      | 39.18      | 41.03     | 46.23     |
| Mixtral-8x7B    | 34.63      | 38.48      | 39.96     | 40.89     |
| Mixtral-8x22B   | 35.33      | 38.48      | 39.49     | 42.24     |
| Llama2-7B       | 36.33      | 44.21      | 44.13     | 46.19     |
| Llama2-13B      | 40.96      | 47.37      | 46.57     | 48.12     |
| Llama2-70B      | 39.78      | 45.97      | 46.37     | 48.24     |
| CodeLlama-7B    | 33.02      | 36.88      | 36.49     | 38.06     |
| CodeLlama-70B   | 38.36      | 38.74      | 39.76     | 37.23     |
| Llama3-8B       | 25.37      | 32.14      | 33.84     | 37.35     |
| Llama3-70B      | 24.79      | 30.08      | 33.18     | 36.45     |
| Gemma-2B        | 16.43      | 21.04      | 21.85     | 25.38     |
| Gemma-7B        | 24.16      | 28.24      | 30.44     | 33.96     |
| GPT-3.5         | 36.83      | 41.59      | 45.59     | 49.48     |
| GPT-4           | 45.62      | 52.59      | 56.22     | 57.33     |

Table 22: CompScore metric in the module summarization benchmark for various LLMs.

• We observe that both increasing the context size and the size of the model leads to higher quality. The GPT4 model outperforms the others, achieving a notable Comp-Score of 57.33. Interestingly, the CodeLlama and Llama3 models show worse performance than the Llama2 model.

### Q40 Is there a repository that links to any or all papers or systems that use the dataset?

• The dataset is currently used in our repository with baselines available on GitHub.

### Q41 What tasks could the dataset be used for?

• The dataset can be directly employed for the module summarization task. It might be used for other tasks related to the source code changes.

### Q42 Is there anything about the composition of the dataset or the way it was collected and preprocessed/cleaned/labeled that might impact future uses?

• Not in the data itself. As per the GitHub acceptable usage requirements, researchers using this dataset must make any papers resulting from it available as open access.

### Q43 Are there tasks for which the dataset should not be used?

- To the best of our knowledge, no.
- Q44 Any other comments?
	- No.

### F.6 Distribution

- Q45 Will the dataset be distributed to third parties outside of the entity?
	- Yes, the dataset is publicly available on the internet.
- Q46 How will the dataset be distributed? Does the dataset have a digital object identifier (DOI)?
	- The dataset is available through DOI at the HuggingFace Hub: [https://doi.org/](https://doi.org/10.57967/hf/2515) [10.57967/hf/2515](https://doi.org/10.57967/hf/2515).

### Q47 When will the dataset be distributed?

- The dataset is already publicly available.
- Q48 Will the dataset be distributed under a copyright or other intellectual property (IP) license, and/or under applicable terms of use (ToU)?
	- Data coming from GitHub will be re-distributed under the license it was distributed with originally on GitHub (for which we only used permissive licenses). The terms of use require that research conducted with this dataset makes any resulting paper available as open access, in line with GitHub's requirements.

Q49 Have any third parties imposed IP-based or other restrictions on the data associated with the instances?

• No.

- Q50 Do any export controls or other regulatory restrictions apply to the dataset or to individual instances?
	- To the best of our knowledge, no.
- Q51 Any other comments?
	- No.

### F.7 Maintenance

- Q52 Who is supporting/hosting/maintaining the dataset?
	- The dataset will be maintained by the JetBrains Research team.
- Q53 How can the owner/curator/manager of the dataset be contacted (*e.g.*, email address)?
	- The dataset curators can be contacted via email at lca@jetbrains.com.
- Q54 Is there an erratum?
	- There is no erratum as of June 2024.
- Q55 Will the dataset be updated? (*e.g.*, to correct labeling errors, add new instances, delete instances)?
	- The dataset will be extended to more languages and samples over the course of time.
- Q56 If the dataset relates to people, are there applicable limits on the retention of the data associated with the instances?
	- On the HuggingFace Space, we provide information on how individuals can request removals.
- Q57 Will older versions of the dataset continue to be supported/hosted/maintained?
	- The older versions will be kept around for consistency.
- Q58 If others want to extend/augment/build on/contribute to the dataset, is there a mechanism for them to do so?
	- We welcome all contributions and encourage others to contact the dataset curators via the provided email.
- Q59 Any other comments?
	- No.