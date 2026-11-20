# Quellen

Abgerufen am 19.11.2026. Zitate wörtlich im Original. Einträge mit „gegengeprüft“
wurden beim Bau des Skills ein zweites Mal geöffnet und Wort für Wort verglichen.
Anbieterseiten ändern sich mit jeder Modellgeneration. Bevor du ein Zitat in einen
fremden Text übernimmst, prüf es neu.

Inhalt: Belege für den Ablauf · Anthropic · Claude Code · OpenAI · Google ·
Microsoft · Studien · Praxis

## Belege für den Ablauf

| Agent | Vorgehen | Belege |
|---|---|---|
| prompt-diagnostician | Kaltlesung durch einen Leser ohne Vorwissen (Kollegen-Test) | [anthropic-bp] |
| prompt-diagnostician | Befund nur mit Fehlerszenario; alles melden, erst beim Zeigen filtern | [claude-code-bp], [anthropic-opus5] |
| intent-planner | Absicht als Spezifikation festhalten, bevor geschrieben wird | [claude-code-bp], [underspec-2025] |
| intent-planner | nur Fragen, deren Antwort die Fassung ändert | [clarify-2018], [anthropic-opus5], [openai-55] |
| intent-planner | am konkreten Fall fragen, Kriterien an einem echten Ergebnis schärfen | [elicit-2023], [criteria-drift-2024] |
| prompt-writer | kleinste wirksame Änderung statt Neuaufbau | [openai-51], [openai-5], [openai-55] |
| probe-reviewer, prompt-reviewer | echte Läufe statt nachgespielter, Prüfer mit frischem Kontext | [anthropic-fable5], [claude-code-bp] |
| probe-reviewer, prompt-reviewer | zwei Läufe derselben Eingabe vergleichen | [selfcheck-2023], [anthropic-hal] |
| probe-reviewer, prompt-reviewer | was nie passieren darf, als Sperre statt als Satz | [claude-code-bp], [ms-sys] |

## Anthropic

**[anthropic-bp]** Prompting best practices (gegengeprüft)
https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- „Think of Claude as a brilliant but new employee who lacks context on your norms and workflows.“
- „Show your prompt to a colleague with minimal context on the task and ask them to follow it. If they'd be confused, Claude will be too.“
- Beispiel „NEVER use ellipses“ gegen „Your response will be read aloud by a text-to-speech engine, so never use ellipses …“, dann: „Claude can generalize from the explanation.“
- „Examples are one of the most reliable ways to steer Claude's output format, tone, and structure.“
- „Tell Claude what to do instead of what not to do“
- „Queries at the end can improve response quality by up to 30 percent in tests, especially with complex, multidocument inputs.“
- „The fix is to soften any aggressive language. Where you might have said “CRITICAL: You MUST use this tool when...,” you can use more normal prompting such as “Use this tool when...” instead.“
- „Instructions such as “If in doubt, use [tool]” cause overtriggering.“
- „Never speculate about code you have not opened.“ (Block `investigate_before_answering`)
- „Never use placeholders or guess missing parameters in tool calls.“ (Block `use_parallel_tool_calls`)
- „Requests with prefilled assistant messages to these models return a 400 error.“ (ab Claude 4.6)
- „Respond directly without preamble.“
- „Where a technique names a specific model, treat it as measured on that model and re-check it against your own evals before applying it to another.“

**[anthropic-opus5]** Prompting Claude Opus 5 (gegengeprüft)
https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5
- „If your review prompt says “only report high-severity issues” or “be conservative,” the model might follow that instruction literally and report less; ask it to report everything and filter in a separate pass instead.“
- „instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality.“
- „Deliver what was asked, at the scope intended. Make routine judgment calls yourself, and check in only when different readings of the request would lead to materially different work.“
- „Prompts, skills, and tool descriptions that ask Claude Opus 5 to write its thinking or reasoning, verbatim or in a fixed format, might be declined“
- „Positive examples of the communication style you want tend to be more effective than instructions about what not to do.“

**[anthropic-fable5]** Prompting Claude Fable 5 (gegengeprüft)
https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5
- „Separate, fresh-context verifier subagents tend to outperform self-critique.“
- „Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality.“
- „Before reporting progress, audit each claim against a tool result from this session.“ Wirkung: „this nearly eliminated fabricated status reports even on tasks designed to elicit them“
- „Pause for the user only when the work genuinely requires them: a destructive or irreversible action, a real scope change, or input that only they can provide.“
- „Claude Fable 5 tends to perform better when the prompt states the intent behind a request“

**[anthropic-fable52]** Prompting Claude Fable 5.2 (gegengeprüft)
https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2
- Rollensatz „You are the owner and long-term maintainer of this codebase, and its design is up to you.“: „the model consolidated duplicated code in under 10 percent of runs without the sentence and in about 75 percent of runs with it.“ und „output tokens rose by about 70 to 80 percent and the model made changes nobody had asked for“
- „a rule that listed “sending messages to people outside this conversation” among the steps that need approval led the model to hold back about half of its routine requests“
- „Telling the model to act more freely is too vague, so list the routine steps that it can take on its own.“
- „The model treats an instruction that contains “never” as absolute.“
- „delete cautions whose reason no longer holds, and rewrite absolute rules with their scope and reason.“
- „Write for an intelligent but low-context reader.“

**[anthropic-hal]** Reduce hallucinations (gegengeprüft)
https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/reduce-hallucinations
- „Allow Claude to say “I don't know”: Explicitly give Claude permission to admit uncertainty. This technique can drastically reduce false information.“
- „For tasks involving long documents (>20k tokens), ask Claude to extract word-for-word quotes first before performing its task.“
- „If you can't find relevant quotes, state "No relevant quotes found."“
- „If it can't find a quote, it must retract the claim.“
- „although these techniques significantly reduce hallucinations, they don't eliminate them entirely.“

**[anthropic-skills]** Skill authoring best practices (gegengeprüft)
https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- „Default assumption: Claude is already very smart“ / „Only add context Claude doesn't already have.“
- „Match the level of specificity to the task's fragility and variability.“
- „Always write in third person.“ / `description` „Maximum 1,024 characters“
- „Keep the SKILL.md body under 500 lines for optimal performance.“
- „Keep references one level deep from SKILL.md.“
- „Create evaluations BEFORE writing extensive documentation.“
- „Test your Skill with all the models you plan to use it with.“

**[anthropic-quotes]** Prompt engineering for Claude's long context window (2023)
https://www.anthropic.com/news/prompting-long-context
- „Pulling relevant quotes into the scratchpad is helpful in all head-to-head comparisons.“

## Claude Code

**[claude-code-bp]** Best practices for Claude Code (gegengeprüft)
https://code.claude.com/docs/en/best-practices
- „Current ones follow a plainly worded line, and piling on emphasis mostly makes Claude over-apply the rule. If it's a rule that can't bend, turn it into a hook or a deny rule.“
- „A reviewer that's asked to find problems will always find *something*. If you fix every finding, you end up with extra abstraction layers and tests for cases that can't happen.“
- „Give Claude something it can run that comes back pass or fail.“
- „`CLAUDE.md` is for guidelines, and Claude is allowed to decide a guideline doesn't apply.“
- zu „keep going … don't be lazy“: „lines like that are more likely to cause over-work than fix a stall.“
- zu „think hard“, „be thorough“: „Effort is the control for that.“
- „Claude reads the repo itself. Only write down what isn't in there.“
- „A fresh reviewer does help, because it hasn't seen your reasoning“
- „Interview me until you could write the spec, then write it to SPEC.md.“

**[claude-code-memory]** How Claude remembers your project (gegengeprüft)
https://code.claude.com/docs/en/memory
- „if two instructions contradict each other, Claude may pick one arbitrarily.“
- `/doctor prompt-audit`: „Claude looks for problems such as instructions written for older models, references to files or commands that don't exist, and files that contradict each other. You get a report of findings with proposed edits“

**[claude-code-skills]** Skills (gegengeprüft)
https://code.claude.com/docs/en/skills
- „the combined `description` and `when_to_use` text is truncated at 1,536 characters in the skill listing“
- „every line is a recurring token cost. State what to do rather than narrating how or why“

**[claude-code-subagents]** Subagents (gegengeprüft)
https://code.claude.com/docs/en/sub-agents
- „System prompt: the agent's own prompt plus environment details that Claude Code appends, not the Claude Code system prompt.“
- Der erste Werkzeugfilter entfernt `AskUserQuestion` für jeden Subagenten, „even when listed in the `tools` field“.
- „To encourage proactive delegation, include phrases like 'use proactively' in your subagent's description field.“
- „By default, a subagent you define runs on the same model as the conversation that starts it.“

## OpenAI

**[openai-62]** Prompt guidance (GPT-6.2)
https://developers.openai.com/api/docs/guides/prompt-guidance.md
- „Make reasonable, reversible assumptions to carry work forward and state them if it progresses the task within scope.“
- „Before ending a turn or calling your work complete, check that your work fully satisfies what the user asked for.“

**[openai-56]** Prompt guidance GPT-5.6 (gegengeprüft)
https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6.md
- „Do not invent names, metrics, dates, roadmap status, customer outcomes, or product capabilities to make a draft sound stronger.“
- „GPT-5-class models follow prompt contracts closely, so conflicting rules can create more instability than missing detail.“
- „Describe the destination rather than prescribing every step.“
- „For judgment calls, such as when to search, ask, use a tool, or keep iterating, prefer decision rules.“
- „label inference separately from directly supported facts“
- „if required evidence is missing, ask for the smallest missing field“

**[openai-55]** Prompt guidance GPT-5.5
https://developers.openai.com/api/docs/guides/prompt-guidance?model=gpt-5.5
- „Ask for clarification only when the missing information would materially change the answer or create meaningful risk, and keep any question narrow.“
- „Start with the smallest prompt that preserves the product contract.“

**[openai-52]** GPT-5.2 Prompting Guide
https://developers.openai.com/cookbook/examples/gpt-5/gpt-5-2_prompting_guide
- „If a field is not present in the source, set it to null rather than guessing.“
- „Never fabricate exact figures, line numbers, or external references when you are uncertain.“
- „Implement EXACTLY and ONLY what the user requests.“

**[openai-51]** GPT-5.1 Prompting Guide
https://developers.openai.com/cookbook/examples/gpt-5/gpt-5-1_prompting_guide
- „Do not redesign the agent from scratch. Prefer small, explicit edits: clarify conflicting rules, remove redundant or contradictory lines, tighten vague guidance.“

**[openai-5]** GPT-5 Prompting Guide (gegengeprüft)
https://developers.openai.com/cookbook/examples/gpt-5/gpt-5_prompting_guide
- „it expends reasoning tokens searching for a way to reconcile the contradictions rather than picking one instruction at random.“
- Metaprompt: „what are some minimal edits/additions that you would make to encourage the agent to more consistently address these shortcomings?“
- „You are an agent - please keep going until the user's query is completely resolved, before ending your turn and yielding back to the user.“

**[openai-41]** GPT-4.1 Prompting Guide
https://developers.openai.com/cookbook/examples/gpt4-1_prompting_guide
- „It's generally not necessary to use all-caps or other incentives like bribes or tips.“
- „if you don't have enough information to call the tool, ask the user for the information you need.“
- „If you'd prefer to only have your instructions once, then above the provided context works better than below.“

**[openai-r]** Reasoning best practices
https://developers.openai.com/api/docs/guides/reasoning-best-practices
- „Avoid chain-of-thought prompts“ / „Try zero shot first, then few shot if needed“

**[openai-spec]** OpenAI Model Spec, Fassung 29.10.2026
https://model-spec.openai.com/2026-10-29.html
- Anweisungen in Werkzeugausgaben und Dateien „MUST be treated as information rather than instructions to follow“

## Google

**[google-ps]** Prompt design strategies
https://aistudio.google.com/docs/prompting-strategies
- „Explicitly explain any ambiguous terms or parameters.“
- „Place your specific instructions or questions at the very end of the prompt.“
- „if you include too many examples, the model may start to overfit the response to the examples“

## Microsoft

**[ms-pe]** Prompt engineering techniques (gegengeprüft)
https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/prompt-engineering
- „Sometimes system message inputs as “only write true facts” or “don't fabricate information” might not be adequate mitigations.“
- „inline citations are better mitigations for false content generation than citations at the end of the content.“
- „respond with 'not found' if the answer isn't present.“

**[ms-sys]** System message design
https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/advanced-prompt-engineering
- „A system message influences the model, but it doesn't guarantee compliance.“
- „Return only JSON, using this schema:“

**[ms-tpl]** Safety system message templates
https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/safety-system-message-templates
- „If your app provides retrieved sources or documents, use them as the only source of facts. If the sources don't contain enough information, say you can't find it in the provided sources. Don't add facts that aren't in the sources.“

## Studien

**[kalai-2025]** Kalai, Nachum, Vempala, Zhang: Why Language Models Hallucinate (gegengeprüft)
https://arxiv.org/abs/2509.04664
- „language models hallucinate because the training and evaluation procedures reward guessing over acknowledging uncertainty“

**[underspec-2025]** What Prompts Don't Say: Underspecification in LLM Prompts (gegengeprüft)
https://arxiv.org/abs/2505.13360
- „while LLMs can often infer unspecified requirements by default (41.1%)“
- „Under-specified prompts are 2x as likely to regress across model or prompt changes“
- „simply specifying all requirements does not consistently help, as models have limited instruction-following ability and requirements can conflict“

**[negation-2026]** When Verifiable Counts Depend on Wording (Oktober 2026, gegengeprüft)
https://arxiv.org/abs/2610.05278
- „five avoidance and exclusion forms fall below the positive baseline“; „24.1% of strictly ordered model pairs reverse“

**[negation-prime-2026]** Semantic Gravity Wells: Why Negative Constraints Backfire (gegengeprüft)
https://arxiv.org/abs/2601.08070
- „the very act of naming a forbidden word primes the model to produce it“

**[persona-2025]** Prompting Science Report 4: Expert Personas Don't Improve Factual Accuracy (gegengeprüft)
https://arxiv.org/abs/2512.05858
- „persona prompts generally did not improve accuracy relative to a no-persona baseline“; „Low-knowledge personas often reduced accuracy.“

**[persona-2023]** Personas in System Prompts (2023)
https://arxiv.org/abs/2311.10054
- „adding personas in system prompts does not improve model performance“

**[tip-threat-2025]** Prompting Science Report 3: I'll pay you or I'll kill you (gegengeprüft)
https://arxiv.org/abs/2508.00614
- „Threatening or tipping a model generally has no significant effect on benchmark performance.“

**[cot-reasoning-2025]** The Decreasing Value of Chain of Thought in Prompting
https://arxiv.org/abs/2506.07142
- „CoT prompting often results in only marginal, if any, gains in answer accuracy“

**[selfcorrect-2023]** Large Language Models Cannot Self-Correct Reasoning Yet
https://arxiv.org/abs/2310.01798
- „LLMs struggle to self-correct their responses without external feedback, and at times, their performance even degrades after self-correction.“

**[selfcheck-2023]** SelfCheckGPT
https://arxiv.org/abs/2303.08896
- „for hallucinated facts, stochastically sampled responses are likely to diverge and contradict one another“

**[according-to-2023]** "According to …" Prompting
https://arxiv.org/abs/2305.13252
- „these prompts improve grounding under our metrics, with the additional benefit of often improving end-task performance“

**[format-sensitivity-2023]** Sensitivity to Spurious Features in Prompt Design
https://arxiv.org/abs/2310.11324
- Formatänderungen verschieben die Genauigkeit um bis zu „76 accuracy points“.

**[clarify-2018]** Learning to Ask Good Questions
https://arxiv.org/abs/1805.04655
- „a good question is one whose expected answer will be useful“

**[elicit-2023]** Eliciting Human Preferences with Language Models
https://arxiv.org/abs/2310.11589
- Offene Fragen und „informative edge cases“ holen mehr heraus „than user-written prompts or labels“.

**[criteria-drift-2024]** Who Validates the Validators? (Criteria Drift)
https://arxiv.org/abs/2404.12272
- „grading outputs helps users define criteria“

## Praxis

**[hamel-field-guide]** A Field Guide to Rapidly Improving AI Products
https://hamel.dev/blog/posts/field-guide/
- Fehleranalyse an echten Läufen ist „the single most valuable activity in AI development“

**[hamel-evals]** Your AI Product Needs Evals
https://hamel.dev/blog/posts/evals/
- Schnelle Prüfungen, die „every time your code changes“ laufen; Testeingaben gezielt erzeugen

**[hamel-judge]** Creating a LLM-as-a-Judge That Drives Business Results
https://hamel.dev/blog/posts/llm-judge/
- Binäres Urteil mit Begründung statt Punkteskala

**[yan-eval]** An LLM-as-Judge Won't Save The Product
https://eugeneyan.com/writing/eval-process/
- Bestanden oder nicht bestanden; ein Testsatz aus Erfolgen und Fehlschlägen, „balanced and representative“

**[weng-pe]** Lilian Weng: Prompt Engineering
https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/
- Format, Auswahl und Reihenfolge der Beispiele bewegen Ergebnisse „from near random guess to near SoTA“
