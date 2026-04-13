-- Soften intermediate/advanced questions with "even just a little?" or gentler framing

UPDATE question_pool SET question = 'Did fear of losing money stop you from a decision — even just a little?'
WHERE question = 'Did fear of losing money stop you from a decision that made sense?';

UPDATE question_pool SET question = 'Did you choose immediate comfort over a future goal — even a small one?'
WHERE question = 'Did you choose immediate comfort over a future financial goal?';

UPDATE question_pool SET question = 'Did a number you saw early in a decision influence you — even slightly?'
WHERE question = 'Did a number you encountered early in a decision influence the outcome more than it should?';

UPDATE question_pool SET question = 'Did you skip research because you felt you already knew enough — even a little?'
WHERE question = 'Did you skip research because you felt you already knew enough?';

UPDATE question_pool SET question = 'Did you avoid switching something financial because it felt like effort — even just a bit?'
WHERE question = 'Did you avoid switching something financial because changing felt like too much effort?';

UPDATE question_pool SET question = 'Did you feel more desire for something because it seemed scarce — even briefly?'
WHERE question = 'Did you feel more desire for something because it was scarce or hard to get?';

UPDATE question_pool SET question = 'Did a financial win make you feel like you could splurge — even just a little?'
WHERE question = 'Did a financial win make you feel licensed to splurge elsewhere?';

UPDATE question_pool SET question = 'Did you make a money decision when you were tired or stressed — even a small one?'
WHERE question = 'Did you make a financial decision when you were stressed, tired, or emotionally drained?';

UPDATE question_pool SET question = 'Did a friend or family member''s situation change how you saw your own — even slightly?'
WHERE question = 'Did a friend or family member''s money situation change how you evaluated your own?';

UPDATE question_pool SET question = 'Did you feel more certain about a financial outcome than the evidence really supported?'
WHERE question = 'Did you feel more certain about a financial outcome than the evidence supported?';
