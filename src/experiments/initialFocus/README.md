Lessons learned:

- initialFocus forwards the setFocus() call to the child indicated
- if setFocus is not called on the parent component, initialFocus will not affect any focus (makes sense, you may want to create a component without it automatically grabbing focus)
- removing a component with focus takes focus from all components, effectively dead-ending the app
- adding a child which has initialFocus set, but not calling setFocus, leaves focus where it is
- removing a node from the graph and adding it back, calling setFocus does NOT respect initialFocus
- Calling setFocus(true) on a parent that isInFocusChain but does not have focus itself will leave focus at the child