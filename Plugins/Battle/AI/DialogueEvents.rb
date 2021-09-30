# Trainer dialogue events!

class TrainerDialogueHandlerHash < HandlerHash2
end

class PokeBattle_AI
	TrainerChoseMoveDialogue                    = TrainerDialogueHandlerHash.new
	PlayerChoseMoveDialogue						= TrainerDialogueHandlerHash.new
	TrainerPokemonFaintedDialogue				= TrainerDialogueHandlerHash.new
	PlayerPokemonFaintedDialogue				= TrainerDialogueHandlerHash.new
	TrainerSendsOutPokemonDialogue				= TrainerDialogueHandlerHash.new
	PlayerSendsOutPokemonDialogue				= TrainerDialogueHandlerHash.new
	TrainerPokemonTookMoveDamageDialogue		= TrainerDialogueHandlerHash.new
	PlayerPokemonTookMoveDamageDialogue			= TrainerDialogueHandlerHash.new
	TrainerPokemonImmuneDialogue				= TrainerDialogueHandlerHash.new
	PlayerPokemonImmuneDialogue					= TrainerDialogueHandlerHash.new
	TrainerPokemonDiesToDOTDialogue				= TrainerDialogueHandlerHash.new
	PlayerPokemonDiesToDOTDialogue				= TrainerDialogueHandlerHash.new
	
	def self.triggerTrainerChoseMoveDialogue(policy,battler,move,target,trainer_speaking,dialogue_array)
		ret = TrainerChoseMoveDialogue.trigger(policy,battler,move,target,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerPlayerChoseMoveDialogue(policy,battler,move,target,trainer_speaking,dialogue_array)
		ret = PlayerChoseMoveDialogue.trigger(policy,battler,move,target,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerTrainerPokemonFaintedDialogue(policy,battler,trainer_speaking,dialogue_array)
		ret = TrainerPokemonFaintedDialogue.trigger(policy,battler,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerPlayerPokemonFaintedDialogue(policy,battler,trainer_speaking,dialogue_array)
		ret = PlayerPokemonFaintedDialogue.trigger(policy,battler,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerTrainerSendsOutPokemonDialogue(policy,battler,trainer_speaking,dialogue_array)
		ret = TrainerSendsOutPokemonDialogue.trigger(policy,battler,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerPlayerSendsOutPokemonDialogue(policy,battler,trainer_speaking,dialogue_array)
		ret = PlayerSendsOutPokemonDialogue.trigger(policy,battler,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerTrainerPokemonTookMoveDamageDialogue(policy,dealer,taker,trainer_speaking,dialogue_array)
		ret = TrainerPokemonTookMoveDamageDialogue.trigger(policy,dealer,taker,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerPlayerPokemonTookMoveDamageDialogue(policy,dealer,taker,trainer_speaking,dialogue_array)
		ret = PlayerPokemonTookMoveDamageDialogue.trigger(policy,dealer,taker,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerTrainerPokemonImmuneDialogue(policy,attacker,target,trainer_speaking,dialogue_array)
		ret = TrainerPokemonImmuneDialogue.trigger(policy,attacker,target,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerPlayerPokemonImmuneDialogue(policy,attacker,target,trainer_speaking,dialogue_array)
		ret = PlayerPokemonImmuneDialogue.trigger(policy,attacker,target,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerTrainerPokemonDiesToDOTDialogue(policy,pokemon,trainer_speaking,dialogue_array)
		ret = TrainerPokemonDiesToDOTDialogue.trigger(policy,pokemon,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
	
	def self.triggerPlayerPokemonDiesToDOTDialogue(policy,pokemon,trainer_speaking,dialogue_array)
		ret = PlayerPokemonDiesToDOTDialogue.trigger(policy,pokemon,trainer_speaking,dialogue_array)
		return (ret!=nil) ? ret : dialogue_array
	end
end