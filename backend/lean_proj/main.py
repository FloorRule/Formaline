from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from fastapi import status
from pydantic import BaseModel
from typing import List
from lean_translator import translate_to_lean
from lean_runner import run_lean

app = FastAPI()

class ProofStep(BaseModel):
    indent: int
    text: str

class ProofRequest(BaseModel):
    proof: List[ProofStep]

@app.post("/compile-proof")
async def compile_proof(proof_request: ProofRequest):
    try:
        lean_code = translate_to_lean(proof_request.proof)
    except ValueError as e:
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "result": {
                    "success": False,
                    "errors": [str(e)],
                    "explanations": ["Make sure the first line of your proof starts with 'proof: <goal>'."]
                }
            }
        )

    result = run_lean(lean_code)
    return {"result": result}
