class MockPersistence
  def initialize
    @objects = {}
  end
  def find_entity(name)
    @objects[name]
  end
  def add_entity(entity)
    @objects[entity.name] = entity
    entity
  end
  def delete_entity(name)
    @objects.delete(name)
  end
  def save_entity(entity)
    @objects[entity.name] = entity
  end
  def entities
    @objects
  end
end
