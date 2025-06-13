// mock-server.js
const express = require('express');
const cors = require('cors'); // To allow cross-origin requests from your Angular app
const app = express();
const port = 4123;

app.use(cors());
app.use(express.json()); // For parsing application/json

// --- Mock Data ---
const searchPDF = [
    {
        "pdfId": "pdf-a1b2c3d4",
        "nome": "Aquilo que fui não sou mais",
        "numero": 0,
    },
    {
        "pdfId": "pdf-e5f6g7h8",
        "nome": "Meu Deus, meu pai",
        "numero": 1,
    },
    {
        "pdfId": "pdf-m3n4o5p6",
        "nome": "O Sangue de Jesus tem poder",
        "numero": 1,
    },
    {
        "pdfId": "pdf-x7y8z9a0",
        "nome": "Todo Poderoso és",
    }
]
const mockPdfs = {
    "pdf-a1b2c3d4": {
        "pdfId": "pdf-a1b2c3d4",
        "nome": "Aquilo que fui não sou mais",
        "numero": 0,
        "classificacao": "ColAdultos",
        "categoria": "Contra Capa",
        "pdf": "http://localhost:4123/mock-pdfs/coladultos-2024-000.pdf",
    },
    "pdf-e5f6g7h8": {
        "pdfId": "pdf-e5f6g7h8",
        "nome": "Meu Deus, meu pai",
        "numero": 1,
        "classificacao": "ColCIAs",
        "categoria": "Clamor",
        "pdf": "http://localhost:4123/mock-pdfs/colcias-2024-001.pdf",
    },
    "pdf-m3n4o5p6": {
        "pdfId": "pdf-m3n4o5p6",
        "nome": "O Sangue de Jesus tem poder",
        "numero": 1,
        "classificacao": "ColAdultos",
        "categoria": "Clamor",
        "pdf": "http://localhost:4123/mock-pdfs/coladultos-2024-001.pdf",
    },
    "pdf-x7y8z9a0": {
        "pdfId": "pdf-x7y8z9a0",
        "nome": "Todo Poderoso és",
        "classificacao": "ACIA",
        "pdf": "http://localhost:4123/mock-pdfs/acia-2024-todo--poderoso--es.pdf",
    }
};

const collections = [
    {
        id: "collection-sduijnq2wel",
        latest: "1.1",
        versions: {
            "1.0": {
                publication_date: "2025-01-01T09:00:00Z",
                description: "Initial January 2025 collection.",
                pdf_ids: ["pdf-x7y8z9a0", "pdf-e5f6g7h8"]
            },
            "1.1": {
                publication_date: "2025-01-15T11:30:00Z",
                description: "January 2025 collection - Added new market analysis, removed old report.",
                pdf_ids: ["pdf-x7y8z9a0", "pdf-a1b2c3d4", "pdf-m3n4o5p6"]
            }
        }
    }
]

const mockTagCollections = {
    "MonthlyBriefing": {
        "1.0": {
            collection_name: "MonthlyBriefing",
            version: "1.0",
            publication_date: "2025-01-01T09:00:00Z",
            description: "Initial January 2025 briefing documents.",
            pdf_ids: ["pdf-a1b2c3d4", "pdf-e5f6g7h8"]
        },
        "1.1": {
            collection_name: "MonthlyBriefing",
            version: "1.1",
            publication_date: "2025-01-15T11:30:00Z",
            description: "January 2025 briefing - Added new market analysis, removed old report.",
            pdf_ids: ["pdf-a1b2c3d4", "pdf-m3n4o5p6"]
        }
    },
    "ExecutiveSummary": {
        "1.0": {
            collection_name: "ExecutiveSummary",
            version: "1.0",
            publication_date: "2025-03-01T09:00:00Z",
            description: "First quarter executive summary.",
            pdf_ids: ["pdf-a1b2c3d4"]
        }
    }
};

// --- Mock Endpoints ---

app.get('/api/search/:s', (req, res) => {
    const searchTerm = req.params.s.toLowerCase();
    const louvores = searchPDF.filter(pdf => pdf.nome.toLowerCase().includes(searchTerm) || pdf?.numero?.toString() === searchTerm);   
    res.json(louvores);
});

app.get('/api/pdf/:id', (req, res) => {
    const pdfId = req.params.id;
    const pdf = mockPdfs[pdfId];
    if (pdf) {
        res.json(pdf);
    } else {
        res.status(404).send('PDF not found');
    }
});

app.get('/api/pdfFile/:id', (req, res) => {
    const pdfId = req.params.id;
    const pdf = mockPdfs[pdfId];
    if (pdf) {
        res.json(pdf['pdf']);
    } else {
        res.status(404).send('PDF not found');
    }
});

app.get('/api/collections', (req, res) => {
    res.json(collections);
});
app.get('/api/collections/:id', (req, res) => {
    const collectionId = req.params.id;
    const collection = collections.find(c => c.id === collectionId);
    if (collection) {
        res.json(collection);
    } else {
        res.status(404).send('Collection not found');
    }
});

app.get('/api/collections/:idCollection/latest', (req, res) => {
    const collectionId = req.params.idCollection;
    const collection = collections.find(c => c.id === collectionId);
    if (collection) {
        const latestVersion = collection.latest;
        res.json(collection.versions[latestVersion]);
    } else {
        res.status(404).send('Collection not found');
    }
});

// Simulate PDF files being served locally
// You'd place dummy PDF files in a 'mock-pdfs' directory
const path = require('path');
app.use('/mock-pdfs', express.static(path.join(__dirname, 'mock-pdfs')));


app.listen(port, () => {
    console.log(`Mock server listening at http://localhost:${port}`);
    console.log(`Access dummy PDFs at http://localhost:${port}/mock-pdfs/`);
});