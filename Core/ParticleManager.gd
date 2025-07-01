class_name ParticleManager
extends Node

class ParticleEntry:
	var node: GPUParticles2D
	var target_amount: int
	var increase_rate: int
	var timer := 0.0
	var state := 0  # 0: waiting, 1: warming

	func _init(_node, _amount, _rate):
		node = _node
		target_amount = _amount
		increase_rate = _rate

var active_particles: Array[ParticleEntry] = []

func add_particle(p: GPUParticles2D, target_amount := 50, increase_rate := 2):
	p.emitting = false
	p.amount = 1
	p.visible = false
	
	var entry := ParticleEntry.new(p, target_amount, increase_rate)
	active_particles.append(entry)

func _process(delta):
	if active_particles.is_empty():
		set_process(false)
		return
	var done_entries := []
	for entry in active_particles:
		match entry.state:
			0:
				entry.timer += delta
				if entry.timer >= 0.2:
					entry.node.emitting = true
					entry.state = 1
			1:
				if entry.node.amount < entry.target_amount:
					entry.node.amount += entry.increase_rate
				else:
					entry.node.amount = entry.target_amount
					entry.node.visible = true
					done_entries.append(entry)
	
	for entry in done_entries:
		active_particles.erase(entry)
	if active_particles.is_empty():
		set_process(false)
