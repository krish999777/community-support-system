import imageCompression from 'browser-image-compression';
import * as pdfjsLib from 'pdfjs-dist';

// Setup Mozilla's PDF.js worker via a highly reliable CDN unpkg with dynamic versioning
pdfjsLib.GlobalWorkerOptions.workerSrc = `https://unpkg.com/pdfjs-dist@${pdfjsLib.version}/build/pdf.worker.min.mjs`;

/**
 * Converts the first page of a PDF file into a JPEG File object.
 */
const convertFirstPageToImage = async (file) => {
  return new Promise((resolve, reject) => {
    const fileReader = new FileReader();
    
    fileReader.onload = async function () {
      try {
        const typedarray = new Uint8Array(this.result);
        
        // Load the PDF Document
        const loadingTask = pdfjsLib.getDocument({ data: typedarray });
        const pdf = await loadingTask.promise;
        
        // Get the first page
        const page = await pdf.getPage(1);
        
        // Scale it up temporarily to maintain high quality before the actual compression
        const scale = 2.0; 
        const viewport = page.getViewport({ scale });
        
        // Render it to a canvas
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        
        const renderContext = {
          canvasContext: context,
          viewport: viewport
        };
        
        await page.render(renderContext).promise;
        
        // Convert canvas into a JPEG Blob -> File
        canvas.toBlob(
          (blob) => {
            if (blob) {
              // Create a brand new File object, replacing .pdf with .jpg
              const newFileName = file.name.replace(/\.pdf$/i, '.jpg');
              const imageFile = new File([blob], newFileName, {
                type: 'image/jpeg',
                lastModified: Date.now()
              });
              resolve(imageFile);
            } else {
              reject(new Error('Failed to convert PDF canvas to image.'));
            }
          },
          'image/jpeg',
          1.0 // Maximum quality for the initial extract
        );
      } catch (err) {
        console.error("PDF Parsing Error: ", err);
        reject(new Error(`Could not process PDF: ${err.message}`));
      }
    };
    
    fileReader.onerror = () => reject(new Error('Failed to read the file from disk.'));
    fileReader.readAsArrayBuffer(file);
  });
};

export const processFileUpload = async (file) => {
  if (!file) return null;

  let fileToCompress = file;

  // 1. If it's a PDF, convert it to a JPEG image first
  if (file.type === 'application/pdf') {
    try {
      fileToCompress = await convertFirstPageToImage(file);
    } catch (error) {
      throw error;
    }
  }

  // 2. Compress the Image (either an uploaded image or the newly extracted PDF image)
  if (fileToCompress && fileToCompress.type.startsWith('image/')) {
    const options = {
      maxSizeMB: 0.3, // Output max size ~300KB
      maxWidthOrHeight: 1200, // Reasonable resolution 
      useWebWorker: true,
      fileType: 'image/jpeg' 
    };
    try {
      const compressedFile = await imageCompression(fileToCompress, options);
      // Construct a new File to keep naming consistent and avoid generic 'blob' names
      return new File([compressedFile], fileToCompress.name, { type: 'image/jpeg' });
    } catch (error) {
      throw new Error('Failed to auto-compress the image. Please try a different file.');
    }
  }

  // 3. Reject completely unsupported files
  throw new Error('Unsupported file type. Please upload an image (JPG/PNG) or a PDF.');
};
