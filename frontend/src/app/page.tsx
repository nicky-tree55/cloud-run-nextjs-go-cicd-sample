export default async function Home() {
  const backendUrl:string = process.env.NEXT_PUBLIC_API_URL || '';

  if (backendUrl === '') {
    return (
      <h1>BACKEND_URL is not set. Current value: {backendUrl}</h1>
    );
  } else {
    try {
      const dynamicData = await fetch(backendUrl, { cache: 'no-store' });
      if (!dynamicData.ok) {
        throw new Error(`HTTP error! status: ${dynamicData.status}`);
      }
      const data = await dynamicData.text();

      return (
        <h1>{data}</h1>
      );
    } catch (error) {
      return (
        <h1>Error fetching data: {(error as Error).message}. Current value: {backendUrl}</h1>
      );
    }
  }
}