import {
  NodemailerEmailService,
  ResendEmailService,
  buildEmailHtml,
  IEmailService,
  LancamentoEmailData,
} from "../services/emailService";
import nodemailer from "nodemailer";

jest.mock("nodemailer");

// Mock do SDK Resend
const mockResendSend = jest.fn();
jest.mock("resend", () => ({
  Resend: jest.fn().mockImplementation(() => ({
    emails: { send: mockResendSend },
  })),
}));

const mockSendMail = jest.fn().mockResolvedValue({ messageId: "test-id" });
const mockCreateTransport = nodemailer.createTransport as jest.Mock;

function makeLancamento(
  overrides: Partial<LancamentoEmailData> = {},
): LancamentoEmailData {
  return {
    id: 1,
    descricao: "Salário",
    data_lancamento: "2026-01-05",
    valor: 5000,
    tipo_lancamento: "RECEITA",
    situacao: "ATIVO",
    ...overrides,
  };
}

describe("NodemailerEmailService", () => {
  let service: IEmailService;

  beforeEach(() => {
    jest.clearAllMocks();
    mockCreateTransport.mockReturnValue({ sendMail: mockSendMail });
    service = new NodemailerEmailService();
  });

  afterEach(() => {
    delete process.env.SMTP_HOST;
    delete process.env.SMTP_USER;
    delete process.env.SMTP_PASS;
    delete process.env.NOTIFICATION_EMAIL;
  });

  // Test 1
  it("skips sending when SMTP config is missing and does not throw", async () => {
    // No env vars set
    await expect(
      service.sendLancamentoNotification(makeLancamento(), "created"),
    ).resolves.not.toThrow();
    expect(mockSendMail).not.toHaveBeenCalled();
  });

  // Test 2
  it("calls sendMail exactly once when config is present", async () => {
    process.env.SMTP_HOST = "smtp.example.com";
    process.env.SMTP_USER = "user@example.com";
    process.env.SMTP_PASS = "secret";
    process.env.NOTIFICATION_EMAIL = "notify@example.com";

    await service.sendLancamentoNotification(makeLancamento(), "created");

    expect(mockSendMail).toHaveBeenCalledTimes(1);
  });

  // Test 3
  it("sends email with action 'created' reflected in subject", async () => {
    process.env.SMTP_HOST = "smtp.example.com";
    process.env.SMTP_USER = "user@example.com";
    process.env.SMTP_PASS = "secret";
    process.env.NOTIFICATION_EMAIL = "notify@example.com";

    await service.sendLancamentoNotification(makeLancamento(), "created");

    const callArgs = mockSendMail.mock.calls[0][0];
    expect(callArgs.subject).toContain("criado");
  });

  // Test 4
  it("sends email with action 'updated' reflected in subject", async () => {
    process.env.SMTP_HOST = "smtp.example.com";
    process.env.SMTP_USER = "user@example.com";
    process.env.SMTP_PASS = "secret";
    process.env.NOTIFICATION_EMAIL = "notify@example.com";

    await service.sendLancamentoNotification(makeLancamento(), "updated");

    const callArgs = mockSendMail.mock.calls[0][0];
    expect(callArgs.subject).toContain("atualizado");
  });

  // Test 5
  it("propagates errors thrown by the mail transporter", async () => {
    process.env.SMTP_HOST = "smtp.example.com";
    process.env.SMTP_USER = "user@example.com";
    process.env.SMTP_PASS = "secret";
    process.env.NOTIFICATION_EMAIL = "notify@example.com";
    mockSendMail.mockRejectedValueOnce(new Error("SMTP connection failed"));

    await expect(
      service.sendLancamentoNotification(makeLancamento(), "created"),
    ).rejects.toThrow("SMTP connection failed");
  });

  // Test 6
  it("sends DESPESA email with correct tipo in subject", async () => {
    process.env.SMTP_HOST = "smtp.example.com";
    process.env.SMTP_USER = "user@example.com";
    process.env.SMTP_PASS = "secret";
    process.env.NOTIFICATION_EMAIL = "notify@example.com";

    await service.sendLancamentoNotification(
      makeLancamento({ tipo_lancamento: "DESPESA", valor: 200 }),
      "created",
    );

    const callArgs = mockSendMail.mock.calls[0][0];
    expect(callArgs.subject).toContain("Despesa");
  });
});

describe("ResendEmailService", () => {
  let service: IEmailService;

  beforeEach(() => {
    jest.clearAllMocks();
    mockResendSend.mockResolvedValue({
      data: { id: "resend-test-id" },
      error: null,
    });
    service = new ResendEmailService();
  });

  afterEach(() => {
    delete process.env.RESEND_API_KEY;
    delete process.env.NOTIFICATION_EMAIL;
  });

  // Test R1
  it("skips sending when config is missing and does not throw", async () => {
    await expect(
      service.sendLancamentoNotification(makeLancamento(), "created"),
    ).resolves.not.toThrow();
    expect(mockResendSend).not.toHaveBeenCalled();
  });

  // Test R2
  it("calls resend.emails.send exactly once when config is present", async () => {
    process.env.RESEND_API_KEY = "re_test_key";
    process.env.NOTIFICATION_EMAIL = "pedroscheid10@gmail.com";

    await service.sendLancamentoNotification(makeLancamento(), "created");

    expect(mockResendSend).toHaveBeenCalledTimes(1);
  });

  // Test R3
  it("sends email with action 'created' reflected in subject", async () => {
    process.env.RESEND_API_KEY = "re_test_key";
    process.env.NOTIFICATION_EMAIL = "pedroscheid10@gmail.com";

    await service.sendLancamentoNotification(makeLancamento(), "created");

    const callArgs = mockResendSend.mock.calls[0][0];
    expect(callArgs.subject).toContain("criado");
  });

  // Test R4
  it("sends email with action 'updated' reflected in subject", async () => {
    process.env.RESEND_API_KEY = "re_test_key";
    process.env.NOTIFICATION_EMAIL = "pedroscheid10@gmail.com";

    await service.sendLancamentoNotification(makeLancamento(), "updated");

    const callArgs = mockResendSend.mock.calls[0][0];
    expect(callArgs.subject).toContain("atualizado");
  });

  // Test R5
  it("sends DESPESA email with correct tipo in subject", async () => {
    process.env.RESEND_API_KEY = "re_test_key";
    process.env.NOTIFICATION_EMAIL = "pedroscheid10@gmail.com";

    await service.sendLancamentoNotification(
      makeLancamento({ tipo_lancamento: "DESPESA", valor: 200 }),
      "created",
    );

    const callArgs = mockResendSend.mock.calls[0][0];
    expect(callArgs.subject).toContain("Despesa");
  });

  // Test R6
  it("throws when Resend returns an error object", async () => {
    process.env.RESEND_API_KEY = "re_test_key";
    process.env.NOTIFICATION_EMAIL = "pedroscheid10@gmail.com";
    mockResendSend.mockResolvedValueOnce({
      data: null,
      error: { message: "invalid api key" },
    });

    await expect(
      service.sendLancamentoNotification(makeLancamento(), "created"),
    ).rejects.toThrow("invalid api key");
  });

  // Test R7
  it("sends to the address defined in NOTIFICATION_EMAIL", async () => {
    process.env.RESEND_API_KEY = "re_test_key";
    process.env.NOTIFICATION_EMAIL = "pedroscheid10@gmail.com";

    await service.sendLancamentoNotification(makeLancamento(), "created");

    const callArgs = mockResendSend.mock.calls[0][0];
    expect(callArgs.to).toBe("pedroscheid10@gmail.com");
  });
});

describe("buildEmailHtml", () => {
  // Test 7
  it("includes tipo_lancamento correctly for RECEITA", () => {
    const html = buildEmailHtml(makeLancamento(), "created");
    expect(html).toContain("Receita");
  });

  // Test 8
  it("includes tipo_lancamento correctly for DESPESA", () => {
    const html = buildEmailHtml(
      makeLancamento({ tipo_lancamento: "DESPESA" }),
      "created",
    );
    expect(html).toContain("Despesa");
  });

  // Test 9
  it("includes valor formatted with comma separator", () => {
    const html = buildEmailHtml(makeLancamento({ valor: 1500.5 }), "created");
    expect(html).toContain("1500,50");
  });

  // Test 10
  it("includes data_lancamento in html body", () => {
    const html = buildEmailHtml(makeLancamento(), "created");
    expect(html).toContain("2026-01-05");
  });

  // Test 11
  it("includes descricao in html body", () => {
    const html = buildEmailHtml(
      makeLancamento({ descricao: "Freelance" }),
      "created",
    );
    expect(html).toContain("Freelance");
  });
});
