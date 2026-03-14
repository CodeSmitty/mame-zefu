Flipper.register(:admins) do |actor|
  actor.respond_to?(:is_admin?) && actor.is_admin?
end
