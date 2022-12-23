local currentBeat = 0

function onUpdatePost(dt)
	currentBeat = (getSongPosition() / 1000) * (bpm / 60)
	for i = 0, defaultMania do
		setPropertyFromGroup('playerStrums', i, 'x', getPropertyFromGroup('playerStrums', i, 'x') + (math.sin(currentBeat + 4 + i)) + math.cos(currentBeat + i * .2))
		setPropertyFromGroup('playerStrums', i, 'y', getPropertyFromGroup('playerStrums', i, 'y') + (math.cos(currentBeat + 4 + i)) + math.sin(currentBeat + i * .2))
		
		setPropertyFromGroup('opponentStrums', i, 'x', getPropertyFromGroup('opponentStrums', i, 'x') + (math.sin(currentBeat + 4 + i)) + math.cos(currentBeat + i * .2))
		setPropertyFromGroup('opponentStrums', i, 'y', getPropertyFromGroup('opponentStrums', i, 'y') + (math.cos(currentBeat + 4 + i)) + math.sin(currentBeat + i * .2))
	end
end