// Ambient module declarations to ease TS checks in the frontend

declare module '*.jsx';

declare module 'express' {
  export interface Request {
    [key: string]: any;
    user?: any;
    body: any;
    headers?: any;
  }
  export interface Response {
    status: (code: number) => Response;
    json: (body: any) => any;
  }
  export type NextFunction = (...args: any[]) => any;
}
