ALTER TABLE question_pool ADD COLUMN IF NOT EXISTS research_source text;

UPDATE question_pool SET research_source = 'Prospect Theory — Kahneman & Tversky, 1979' WHERE bias_name = 'Loss Aversion';
UPDATE question_pool SET research_source = 'Judgment Under Uncertainty — Tversky & Kahneman, 1974' WHERE bias_name = 'Anchoring';
UPDATE question_pool SET research_source = 'Hyperbolic Discounting — Laibson, 1997' WHERE bias_name = 'Present Bias';
UPDATE question_pool SET research_source = 'The Ostrich Effect — Galai & Sade, 2006' WHERE bias_name = 'Ostrich Effect';
UPDATE question_pool SET research_source = 'Mental Accounting — Thaler, 1985' WHERE bias_name = 'Mental Accounting';
UPDATE question_pool SET research_source = 'The Sunk Cost Fallacy — Arkes & Blumer, 1985' WHERE bias_name = 'Sunk Cost Fallacy';
UPDATE question_pool SET research_source = 'Influence — Cialdini, 1984' WHERE bias_name = 'Social Proof';
UPDATE question_pool SET research_source = 'Ego Depletion — Baumeister et al, 1998' WHERE bias_name = 'Ego Depletion';
UPDATE question_pool SET research_source = 'Moral Self-Licensing — Merritt et al, 2010' WHERE bias_name = 'Moral Licensing';
UPDATE question_pool SET research_source = 'Status Quo Bias — Samuelson & Zeckhauser, 1988' WHERE bias_name = 'Status Quo Bias';
UPDATE question_pool SET research_source = 'Scarcity — Shah, Mullainathan & Shafir, 2012' WHERE bias_name = 'Scarcity Heuristic';
UPDATE question_pool SET research_source = 'The Denomination Effect — Raghubir & Srivastava, 2009' WHERE bias_name = 'Denomination Effect';
UPDATE question_pool SET research_source = 'The Planning Fallacy — Kahneman & Tversky, 1979' WHERE bias_name = 'Planning Fallacy';
UPDATE question_pool SET research_source = 'Availability Heuristic — Tversky & Kahneman, 1973' WHERE bias_name = 'Availability Heuristic';
UPDATE question_pool SET research_source = 'Framing Effects — Tversky & Kahneman, 1981' WHERE bias_name = 'Framing Effect';
UPDATE question_pool SET research_source = 'Overconfidence — Lichtenstein et al, 1982' WHERE bias_name = 'Overconfidence Bias';
