# Formaline

Formaline is an interactive educational tool designed to assist students in practicing formal mathematical proofs through a structured mobile interface. It translates user-written proofs into Lean code, verifies their correctness, and returns the results with clear, informative feedback.

## Features

* Structured proof editor with hierarchical bullet formatting
* Integrated symbol keyboard for mathematical and logical notation
* Backend translation of natural-language formal proofs to Lean
* Automated validation using the Lean theorem prover
* Detailed explanations of proof errors and inconsistencies

## Project Structure

* `frontend/`: Flutter mobile application
* `backend/`: Python FastAPI service for Lean translation and validation

## Technology Stack

* Frontend: Flutter (Dart)
* Backend: FastAPI (Python)
* Theorem Prover: Lean

## Running the Mobile Application

### Prerequisites

* Flutter SDK installed (see: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install))
* Android or iOS device with developer mode enabled

### Steps

```bash
cd frontend
flutter pub get
flutter run
```

## Running the Backend Server

### Prerequisites

* Python 3.9 or higher
* Lean (with mathlib) installed and available in system path

### Steps

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

By default, the server will be available at `http://localhost:8000`.

## Screenshots

<img src="https://github.com/user-attachments/assets/58c27bb2-cb8f-4ec5-9c5b-9ce009770dbe" width="350">

## Contributing

Contributions are welcome. Please fork the repository, make your changes in a separate branch, and open a pull request with a clear description of your modifications.

## License

This project is distributed under the MIT License. Refer to the `LICENSE` file for more details.

