export type Message = {
  message?: string;
  numericSeverity: number;
};

export type Connection = {
  destination: string;
  jwtToken?: string;
};
