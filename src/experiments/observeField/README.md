Lessons learned:

- observeField and observeFieldScoped both suffer from being "additive" in that "n" observe calls will invoke the callback "n" times
- unobserveField and unobserveFieldScoped called once will remove the "additive" callbacks all at once, no need to call unobserveField/unobserveFieldScoped for every observe call
- callback stack for observerField and observerFieldScoped are separate and limited to scope of the BRS context they are called form.  Example: calling observefield then observeFieldScoped will set up two callbacks, and calling unobserveField will only remove the first leaving the scoped observer intact
- unobserveField will remove all callbacks EVEN FROM OTHER BRS CONTEXTS.  unobserveFieldScoped will limit to only the current context