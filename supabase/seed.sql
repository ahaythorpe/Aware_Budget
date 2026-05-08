-- GoldMind — Question pool seed data
-- Run AFTER schema.sql.

insert into question_pool (question, why_explanation, bias_name) values
('Did you check your bank balance this week?', 'Avoiding financial information increases anxiety over time. Regular exposure reduces the stress response.', 'Ostrich Effect'),
('Did a loss feel worse than a same-sized win felt good?', 'We feel losses approximately twice as intensely as equivalent gains. Recognising this helps us make calmer decisions.', 'Loss Aversion'),
('Did you spend today what was meant for future you?', 'Our brains heavily discount future rewards. Naming this helps close the gap between present and future self.', 'Present Bias'),
('Did you treat a refund differently to money you earned?', 'Money is money regardless of where it came from. Mental accounting tricks us into spending windfalls carelessly.', 'Mental Accounting'),
('Did a sale price make you spend more than planned?', 'The first number we see anchors all decisions that follow. Awareness of anchors reduces their pull.', 'Anchoring'),
('Did you continue something just because you had already paid?', 'Past costs cannot be recovered. Only future value should drive current decisions.', 'Sunk Cost Fallacy'),
('Did you avoid a financial task because it felt too big?', 'Breaking tasks into the smallest possible step reduces avoidance. What is the one minute version of this task?', 'Ostrich Effect'),
('Did social pressure influence a spending decision?', 'We overestimate how much others notice our possessions. Spending for status rarely delivers lasting satisfaction.', 'Social Proof'),
('Did you feel more confident about money than the facts warranted?', 'Overconfidence in financial decisions is common and costly. Checking assumptions before committing reduces risk.', 'Overconfidence Bias'),
('Did you stick with a default option without questioning it?', 'Default options are powerful nudges. Actively choosing rather than accepting defaults keeps you in control.', 'Status Quo Bias'),
('Did scarcity make something feel more valuable?', 'Limited availability triggers urgency that bypasses rational evaluation. Pausing 24 hours before scarce offers often reduces desire.', 'Scarcity Heuristic'),
('Did you round up a small cost to justify a larger one?', 'Small amounts matter and accumulate. Dismissing them as negligible is how budgets silently erode.', 'Denomination Effect'),
('Did an unexpected expense catch you off guard this week?', 'Irregular expenses are predictably unpredictable. A small buffer fund converts crises into inconveniences.', 'Planning Fallacy'),
('Did you reward yourself with spending after a good financial week?', 'Moral licensing allows good behaviour to justify later indulgence. Recognising the pattern interrupts it.', 'Moral Licensing'),
('Did you make a financial decision while stressed or tired?', 'Decision quality drops significantly under stress. High-stakes financial decisions deserve a rested mind.', 'Ego Depletion');
