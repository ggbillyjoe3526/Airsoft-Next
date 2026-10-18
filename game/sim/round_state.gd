class_name RoundState
extends RefCounted
## The match's round flow as plain data. STUB: the rounds part of SC1 fills this in.

enum Phase { LIVE, OVER, MATCH_OVER }

var phase: Phase = Phase.LIVE
