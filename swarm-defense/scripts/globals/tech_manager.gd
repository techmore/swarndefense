extends Node

var techs: Dictionary = {}
var researching: String = ""
var research_progress: float = 0.0

signal tech_researched(tech_id: String)
signal research_started(tech_id: String)
signal research_progress_updated(progress: float)

func _ready() -> void:
    _define_techs()

func _define_techs() -> void:
    add_tech("mining_1", "Advanced Mining", "Mining rate +25%", {"metal": 100}, 30.0, [])
    add_tech("power_1", "Efficient Solar", "Solar output +25%", {"crystal": 80}, 25.0, [])
    add_tech("defense_1", "Reinforced Hulls", "Building HP +30%", {"metal": 120}, 35.0, [])
    add_tech("logistics_1", "Faster Relays", "Comms delay -20%", {"crystal": 60}, 20.0, [])
    add_tech("mining_2", "Deep Core Mining", "Unlock rare resources", {"metal": 300, "crystal": 200}, 60.0, ["mining_1"])
    add_tech("power_2", "Fusion Reactor", "Unlock fusion power plants", {"metal": 400, "crystal": 300}, 75.0, ["power_1"])
    add_tech("defense_2", "Shield Technology", "Buildings gain shield HP", {"metal": 350, "crystal": 250}, 70.0, ["defense_1"])
    add_tech("swarm_biology", "Swarm Analysis", "Reveal Swarm wave composition", {"crystal": 200}, 45.0, ["logistics_1"])

func add_tech(id: String, name: String, description: String, costs: Dictionary, research_time: float, prerequisites: Array) -> void:
    techs[id] = {
        "id": id,
        "name": name,
        "description": description,
        "costs": costs,
        "research_time": research_time,
        "prerequisites": prerequisites,
        "researched": false
    }

func can_research(tech_id: String) -> bool:
    if not techs.has(tech_id):
        return false
    var tech = techs[tech_id]
    if tech.researched:
        return false
    if not researching.is_empty():
        return false
    for prereq in tech.prerequisites:
        if not techs[prereq].researched:
            return false
    return true

func start_research(tech_id: String) -> bool:
    if not can_research(tech_id):
        return false
    researching = tech_id
    research_progress = 0.0
    research_started.emit(tech_id)
    return true

func _process(delta: float) -> void:
    if researching.is_empty():
        return
    var tech = techs[researching]
    research_progress += delta / tech.research_time
    research_progress_updated.emit(research_progress)
    if research_progress >= 1.0:
        tech.researched = true
        tech_researched.emit(researching)
        researching = ""
        research_progress = 0.0
