export class ValidationError extends Error {
  // Store structured field errors: { username: "Already exists", password: "Too short" }
  public readonly errors: Record<string, string>;

  constructor(errors: Record<string, string>) {
    super("Validation Error");
    this.name = "ValidationError";
    this.errors = errors;

    // Restores correct prototype chain in transpiled TypeScript environments
    Object.setPrototypeOf(this, ValidationError.prototype);
  }
}
